#watch __FILE__
class R

  def POST
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
    resource = { Date => Time.now.iso8601,
                 Creator => @r.user
               }
    targetResource = graph[uri] || {}   # POST-target resource
    R.formResource data, resource # parse form
    s = if data.uri # existing resource
          data.uri  # subject-URI
        else # new resource
          @r[:Status] = 201
          t = resource[Title]
          slug = t && !t.empty? && t.slugify || rand.to_s.h[0..7]
          if e # POST to container
            resource[SIOC+'has_container'] = R[uri.t] # containment metadata
            targetResource[Type].justArray.map(&:maybeURI).compact.map{|c| # type(s) of container
              POST[c].do{|h| h[resource,targetResource,@r]}} # target-type handler
            if resource.uri # URI bound by handler
              resource.uri
            else # contained resource
              uri.t + slug + '#'
            end
          elsif Containers[resource[Type].maybeURI] # nonexistent container
            mk                                      # create container
            uri.t                                   # add trailing-slash
          else # basic resource
            uri + '#' + slug
          end
        end
    resource['uri'] ||= s           # identify resource
    R.writeResource resource,true   # write resource
    [303,{'Location' => resource.uri},[]] # send to new resource
  end

  def R.writeResource r, buildDoc = false
    graph = {r.uri => r}         # resource to graph
    ts = Time.now.iso8601.gsub /[-+:T]/, '' # timestamp slug
    path = r.R.fragmentPath      # version base
    doc = path + '/' + ts + '.e' # version
    doc.w graph, true            # write version
    cur = path.a '.e'            # live-resource
    cur.delete if cur.e          # obsolete version
    doc.ln_s cur                 # make version live
    r.R.buildDoc if buildDoc
  end

  def buildDoc
    graph = {}
    fragments.map{|f| f.nodeToGraph graph} # collate fragments
    jsonDoc.w graph, true                  # write doc
    self
  end

  # container for resource fragments
  def fragmentDir
    doc = docroot
    doc.dir + '/' + '.' + doc.basename + '/'
  end

  # container for a fragment
  def fragmentPath
    f = fragment
    f = 'index' if !f
    f = '#' if f.empty?
    fragmentDir + f
  end

  def fragments
    fragmentDir.a('*.e').glob
  end

end
