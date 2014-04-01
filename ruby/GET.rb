class R

  def HTTP_GET
    if file = [self,pathSegment].compact.find(&:f) # file exists, client or server might want another MIME
      a = @r.accept.values.flatten
      accepted = a.empty? || (a.member? file.mimeP) || (a.member? '*/*')
      (!accepted || MIMEcook[file.mimeP]) ?
       resource : (file.env @r).fileGET
    else
      resource
    end
  end

  def HTTP_HEAD
    self.GET.do{|s,h,b|[s,h,[]]}
  end

  def HTTP_OPTIONS
    [200,{},[]]
  end

  def fileGET
    @r['ETag'] = [m,size].h
    condResponse mimeP,->{self}
  end

  def resource # handler search
    paths = pathSegment.cascade
    ['http://'+@r['SERVER_NAME'],""].map{|h| # http://host/path first, then /path (mounted on all hosts)
      paths.map{|p| GET[h + p].do{|fn|
          fn[self,@r].do{|r|return r}}}}
    response
  end

  def response
    m = {'#' => {'uri' => '#', Type => R[HTTP+'Response']}} # Response

    fileset = []
    fileFn = q['set'].do{|s| FileSet[s]} || F['fileset']
    fileFn[self,q,m].do{|files| # file function
      fileset.concat files } # add to set

    q['set'].do{|set|
      ResourceSet[set].do{|setFn| # Resource function
        setFn[self,q,m].do{|resources| # resources
          resources.map{|resource| # docs
            fileset.concat resource.docs}}}} # add to set

    return F[404][self,@r] if fileset.empty?

    @r['ETag'] = [q['view'].do{|v|View[v] && v}, # View
                  fileset.sort.map{|r|[r, r.m]}, # entity version(s)
                  @r.format].h                   # output MIME

    condResponse @r.format, ->{
      puts [uri, @r['HTTP_USER_AGENT'], @r['HTTP_REFERER']].join ' '

      # RDF Model - all input formats are RDF and Writer exists for output MIME
      if @r.format != "text/html" && ! fileset.find{|f| ! f.uri.match /\.(jsonld|nt|n3|rdf|ttl)$/} &&
          format = RDF::Format.for(:content_type => @r.format)
        graph = RDF::Graph.new
        fileset.map{|r| graph.load r.d}
        graph.dump format.to_sym

      else # JSON Model
        fileset.map{|r|r.env(@r).toGraph m}
        Render[@r.format][m, @r]
      end}
  end
  
  def condResponse format, body
    @r['HTTP_IF_NONE_MATCH'].do{|m|
      m.strip.split(/\s*,\s*/).include?(@r['ETag']) && [304,{},[]]} ||
    body.call.do{|body|
      head = {'Content-Type' => format, 'ETag' => @r['ETag']}
      head.update({'Cache-Control' => 'no-transform'}) if format.match /^(audio|image|video)/

      body.class == R ? (Nginx ? [200,head.update({'X-Accel-Redirect' => '/fs' + body.path}),[]] : # Nginx
                         Apache ? [200,head.update({'X-Sendfile' => body.d}),[]] : # Apache
                         (f = Rack::File.new nil; f.instance_variable_set '@path', body.d # Rack
                          f.serving(@r).do{|s,h,b|[s,h.update(head),b]})) :
      [200,head,[body]]}
  end

  GET['/'] = -> e,r {
    i = [e,e.pathSegment].compact.map{|e|e.as 'index.html'}.find &:e # file exists?
    if i && !r['REQUEST_URI'].match(/\?/) # querystring?
      if e.uri[-1] == '/' # inside dir?
        i.env(r).fileGET  # file
      else
        [301, {Location: e.uri.t}, []] # into dir/
      end
    else
      if r['REQUEST_URI'].match(/\/index.(html|jsonld|nt|n3|rdf|ttl|txt)$/) # explicit index
        e.parent.as('').env(r).response # erase virtual index-path
      else
        e.response
      end
    end}

end
