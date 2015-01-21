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
    data = Rack::Request.new(@r).params
    return [400,{},['untyped resource']] unless data[Type] # a type of rdfs:resource will do
    timestamp = Time.now.iso8601
    resource = {Date => timestamp}                          # source resource
    targetResource = graph[uri] || {}                       # target resource
    targetType = targetResource[Type].justArray[0].maybeURI # RDF class of target

    data.map{|p,o|
      o = if o.empty?
            nil
          elsif o.match HTTP_URI # full URI
            o.R
          elsif p == Type # expand prefix to URI
            o.R.expand
          elsif p == Content # sanitized HTML
            StripHTML[o]
          else # String
            o
          end
      resource[p] = o if o} # object to graph

    # apply domain-specific handler
    POST[targetType].do{|h| h[resource,targetResource]}

    # subject URI
    s = if resource.uri # already exists, minted by handler
          resource.uri
        else
          if uri[-1] == '/' # POST to container
            title = resource[Title]
            slug = title && !title.empty? && title.slugify || rand.to_s.h[0..7]
            uri + slug + '#'
          else # doc
            uri + '#'
          end
        end

    resource['uri'] ||= s        # identify resource
    graph = {s => resource}      # resource to graph
    ts = timestamp.gsub /[-+:T]/, '' # timestamp slug
    path = s.R.fragmentPath      # fragment-version URI
    doc = path + '/' + ts + '.e' # fragment-version-doc
    doc.w graph, true            # update fragment-version-doc
    cur = path.a '.e'            # fragment-doc URI
    cur.delete if cur.e          # unlink obsolete fragment-version-doc
    doc.ln cur                   # link current fragment-version-doc
    res = R[s].docroot           # containing-doc URI
    res.buildDoc                 # update containing-doc

  [303,{'Location'=>res.uri},[]] # done
  end

end
