watch __FILE__
class R

  def POST
    return Login[self,@r] if path == '/login'
    return [403,{},[]] if !allowWrite
    case @r['CONTENT_TYPE']
    when /^application\/x-www-form-urlencoded/
      formPOST
    when /^multipart\/form-data/
      filePOST
    when /^text\/(n3|turtle)/
      rdfPOST
    else
      [406,{'Accept-Post' => 'application/x-www-form-urlencoded, text/turtle, text/n3, multipart/form-data'},[]]
    end
  end

  def rdfPOST
    if @r.linkHeader['type'] == Container
      path = child(@r['HTTP_SLUG'] || rand.to_s.h[0..6]).setEnv(@r)
      path.PUT
      if path.e
        [200,@r[:Response].update({Location: path.uri}),[]]
      else
        path.MKCOL
      end
    else
      self.PUT
    end
  end

  def filePOST
    p = (Rack::Request.new env).params
    if file = p['file']
      FileUtils.cp file[:tempfile], child(file[:filename]).pathPOSIX
      file[:tempfile].unlink
      ldp
      [201,@r[:Response].update({Location: uri}),[]]
    end
  end

  def R.formResource form, resource
    form.map{|p,o|                      # form-data to resource
      o = if !o || o.empty?
            nil
          elsif o.match HTTP_URI
            o.R                        # normal URI
          elsif p == Type
            o.R.expand                 # expand prefix-URI
          elsif p == Content
            StripHTML[o]               # sanitize HTML
          else
            o                          # String
          end
      resource[p] = o if o && p.match(HTTP_URI)
    }
  end

  def formPOST
    data = Rack::Request.new(@r).POST   # form
    return [400,{},[]] unless data[Type] && @r.signedIn # accept RDF resources from clients w/ a webID
    resource = {Date=>Time.now.iso8601} # resource
    targetResource = graph[uri] || {}   # POST-target resource
    R.formResource data, resource # parse form
    s = if data.uri # existing resource
          data.uri  # subject-URI
        else # new resource
          @r[:Status] = 201
          if e # POST to container
            resource[SIOC+'has_container'] = R[uri.t] # containment triple
            targetResource[Type].justArray.map(&:maybeURI).compact.map{|c| # type(s) of container
              POST[c].do{|h| h[resource,targetResource]}} # container-specific behaviors
            if resource.uri # URI bound by handler
              resource.uri
            else # contained resource
              t = resource[Title]
              slug = t && !t.empty? && t.slugify || rand.to_s.h[0..7]
              uri.t + slug + '#'
            end
          elsif Containers[resource[Type].maybeURI] # container URI
            uri.t                                   # w/ trailing-slash
          else
            uri + '#'                               # resource URI
          end
        end
    resource['uri'] ||= s        # identify resource
    R.writeResource resource     # write resource
    res = R[s].docroot.buildDoc  # update containing-doc
    [303,{'Location' => res.uri},[]] 
    #res.setEnv(@r).response
  end

  def R.writeResource r
    graph = {r.uri => r}         # resource to graph
    ts = Time.now.iso8601.gsub /[-+:T]/, '' # timestamp slug
    path = r.R.fragmentPath      # version base
    doc = path + '/' + ts + '.e' # version
    doc.w graph, true            # write version
    cur = path.a '.e'            # live-resource
    cur.delete if cur.e          # obsolete version
    doc.ln cur                   # make version live
  end

  def buildDoc
    graph = {}
    fragments.map{|f| f.nodeToGraph graph}
    jsonDoc.w graph, true
    self
  end

end
