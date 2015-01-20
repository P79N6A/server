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
     type = data[Type]
    title = data[Title]
timestamp = Time.now.iso8601

    return [400,{},['untyped resource']] unless type

    @r[:container] = Containers.member?(type)

    resource = {Date => timestamp}                          # source resource
    target = @r[:container] ? descend : self                # target URI
    targetResource = target.graph[target.uri] || {}         # target resource
    targetType = targetResource[Type].justArray[0].maybeURI # RDF class of target

    data.map{|p,o|
      o = if o.empty?
            nil
          elsif o.match HTTP_URI # URI
            o.R
          elsif p == Content # sanitized HTML
            StripHTML[o]
          else # String
            o
          end
      resource[p] = o if o} # object to graph

    POST[targetType].do{|handler| # domain-specific handler
      handler[resource,targetResource]}

    # mint URI if handler skips
    s = resource.uri || (u = (@r[:container] ? (target.uri + (title && !title.empty? && title.slugify || rand.to_s.h[0..7])) : uri) + '#'
                         resource['uri'] = u
                         u)

    graph = {s => resource}      # graph
    ts = timestamp.gsub /[-+:T]/, '' # timestamp slug
    path = s.R.fragmentPath      # fragment-version URI
    doc = path + '/' + ts + '.e' # version storage-doc
    doc.w graph, true            # write version
    cur = path.a '.e'            # canonical URI
    cur.delete if cur.e          # unlink obsolete-version
    doc.ln cur                   # link version
    res = R[s].docroot           # containing resource
    res.buildDoc                 # update doc

  [303,{'Location'=>res.uri},[]] # done
  end

end
