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
  rescue Exception => x
    puts x
    [400,{},[]]
  end

  def formPOST
    data = Rack::Request.new(@r).POST
    return [400,{},[]] unless data[Type] && @r.signedIn # accept RDF resources from clients w/ a webID
    timestamp = Time.now.iso8601
    resource = {Date => timestamp}    # resource
    targetResource = graph[uri] || {} # POST target
    containers = targetResource[Type].justArray.map(&:maybeURI).compact # container type(s)
    data.map{|p,o| # form to graph
      o = if !o || o.empty?
            nil
          elsif o.match HTTP_URI
            o.R # full URI
          elsif p == Type
            o.R.expand # expand prefixURI
          elsif p == Content
            StripHTML[o] # sanitizedHTML
          else
            o # String
          end
      resource[p] = o if o && p.match(HTTP_URI)}
    s = if resource.uri # URI already bound
          resource.uri  # subject URI
        else
          if e # POST to container
            containers.map{|c| # container-specific handler
              POST[c].do{|h| h[resource,targetResource]}}
            if resource.uri # URI bound by handler
              resource.uri
            else
              title = resource[Title]
              slug = title && !title.empty? && title.slugify || rand.to_s.h[0..7]
              uri.t + slug + '#'
            end
          elsif Containers[resource[Type].maybeURI] # creating a container, enforce trailing-slash for consistency
            uri.t
          else
            uri + '#' + (resource['fragment']||'') # basic URI
          end
        end

    resource['uri'] ||= s        # identify resource
    graph = {s => resource}      # resource to graph
    ts = timestamp.gsub /[-+:T]/, '' # timestamp slug
    path = s.R.fragmentPath      # fragment-version URI
    doc = path + '/' + ts + '.e' # fragment-version-doc
    doc.w graph, true            # update fragment-version-doc
    cur = path.a '.e'            # fragment-doc URI
    cur.delete if cur.e          # unlink
    doc.ln cur                   # link fragment-version-doc to fragment-doc
    res = R[s].docroot           # containing-doc URI
    res.buildDoc                 # update containing-doc

  [303,{'Location'=>res.uri},[]] # done
  end

end
