class R

  def GET
    if file = [self,pathSegment].compact.find(&:f) # file exists, but client (or server) might want another MIME
      a = @r.accept.values.flatten
      accepted = a.empty? || (a.member? file.mimeP) || (a.member? '*/*')
      return file.setEnv(@r).fileGET unless !accepted || MIMEcook[file.mimeP]
    end # enable conneg-hint paths:
    uri = stripDoc # doc-format in extension
    uri = uri.parent.descend if uri.to_s.match(/\/index$/)
    uri.setEnv(@r).resourceGET # continue at generic-resource URI
  end

  def HEAD
    self.GET.do{|s,h,b|[s,h,[]]}
  end

  def fileGET
    @r['ETag'] = [m,size].h
    condResponse mimeP,->{self}
  end

  def resourceGET # handler cascade
    paths = pathSegment.cascade
    ['http://'+@r['SERVER_NAME'],""].map{|h| # http://host/path first, then /path (mounted on all hosts)
      paths.map{|p| GET[h + p].do{|fn|
#          puts "#{h}#{p} handling"
          fn[self,@r].do{|r|return r}}}}
    response
  end

  def response # default handler
    m = {'#' => {'uri' => '#', Type => R[HTTP+'Response']}} # Response
  set = []
    
    # File set
    fileFn = q['set'].do{|s| FileSet[s]} || FileSet['default']
    fileFn[self,q,m].do{|files| set.concat files }

    # Resource set
    q['set'].do{|s|
      ResourceSet[s].do{|resFn|
        resFn[self,q,m].do{|resources|
          resources.map{|resource|
            set.concat resource.fileResources}}}}

    return E404[self,@r,m] if set.empty?

    @r['ETag'] = [q['view'].do{|v|View[v] && v}, # View
                  set.sort.map{|r|[r, r.m]}, # entity version(s)
                  @r.format].h                   # output MIME

    condResponse @r.format, ->{
      puts ['http://'+@r['SERVER_NAME']+@r['REQUEST_URI'], @r['HTTP_USER_AGENT'], @r['HTTP_REFERER']].join ' '
      
      # RDF Model - all input formats are RDF and Writer exists for output MIME
      if @r.format != "text/html" && !set.find{|f| !f.uri.match /\.(jsonld|nt|n3|rdf|ttl)$/} &&
          format = RDF::Writer.for(:content_type => @r.format)
        graph = RDF::Graph.new
        set.map{|r| graph.load r.d}
        graph.dump format.to_sym

      else # JSON Model
        set.map{|r|r.setEnv(@r).toGraph m}
        Render[@r.format][m, @r]
      end}
  end
  
  def condResponse format, body
    @r['HTTP_IF_NONE_MATCH'].do{|m|
      m.strip.split(/\s*,\s*/).include?(@r['ETag']) && [304,{},[]]} ||
    body.call.do{|body|
      head = {
        'Access-Control-Allow-Origin' => '*',
        'Content-Type' => format,
        'ETag' => @r['ETag'],
      }
      head.update({'Cache-Control' => 'no-transform'}) if format.match /^(audio|image|video)/

      body.class == R ? (Nginx ? [200,head.update({'X-Accel-Redirect' => '/fs' + body.path}),[]] : # Nginx
                         Apache ? [200,head.update({'X-Sendfile' => body.d}),[]] : # Apache
                         (f = Rack::File.new nil; f.instance_variable_set '@path', body.d # Rack
                          f.serving(@r).do{|s,h,b|[s,h.update(head),b]})) :
      [200,head,[body]]}
  end

end
