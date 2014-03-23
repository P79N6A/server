class R
  
  Apache = ENV['apache'] # apache=true in shell-environment
  Nginx  = ENV['nginx']

  def GET
    if file = [self,pathSegment].compact.find(&:f) # file exists, client or server might want another MIME
      a = @r.accept.values.flatten
      accepted = a.empty? || (a.member? file.mimeP) || (a.member? '*/*')
      (!accepted || MIMEcook[file.mimeP]) ?
       resource : (file.env @r).fileGET
    else
      resource
    end
  end

  def HEAD
    self.GET.do{|s,h,b|[s,h,[]]}
  end

  def OPTIONS
    [200,{},[]]
  end

  def fileGET
    @r['ETag'] = [m,size].h
    condResponse mimeP,->{self}
  end

  def resource # handler search
    pathSegment.do{|path|
      paths = path.cascade.map{|p| p.uri.t + 'GET' }
      ['http://'+@r['SERVER_NAME'],""].map{|h| # http://host/path first, then /path (mounted on all hosts)
        paths.map{|p| # bubble up path-tree
          F[h + p].do{|fn| # function found
            fn[self,@r].do{|r| # inspect resource-response for logging
              $stdout.puts [r[0],'http://'+@r['SERVER_NAME']+@r['REQUEST_URI'],@r['HTTP_USER_AGENT'],@r['HTTP_REFERER']].join ' '
              return r
            }}}}}
    response
  end

  def response
    m = {'#' => {'uri' => '#', Type => R[HTTP+'Response']}} # model w/ request-resource

    fileset = [] # empty set
    fileFn = q['set'].do{|s| F['fileset/'+s]} || F['fileset']
    fileFn[self,q,m].do{|files| # find files
      fileset.concat files } # add to set

    q['set'].do{|set| # resource-set
      F['set/' + set].do{|setFn| # function found
        setFn[self,q,m].do{|resources| # resources found
          resources.map{|resource| # map to docs
            fileset.concat resource.docs}}}} # add to set

    return F[404][self,@r] if fileset.empty?

    # response identity
    @r['ETag'] = [q['view'].do{|v|F['view/'+v] && v}, # view
                  fileset.sort.map{|r|[r, r.m]},      # resource version(s)
                  @r.format].h                        # response MIME

    condResponse @r.format, ->{
      fileset.map{|r|r.env(@r).toGraph m} # expand graph
      render @r.format, m, @r} # model -> view -> response
  end
  
  def condResponse format, body
    @r['HTTP_IF_NONE_MATCH'].do{|m|
      m.strip.split(/\s*,\s*/).include?(@r['ETag']) && # client has entity
      [304,{},[]]} ||
    body.call.do{|body|
      head = {'Content-Type' => format, 'ETag' => @r['ETag']}
      head.update({'Cache-Control' => 'no-transform'}) if format.match /^(audio|image|video)/

      body.class == R ? (Nginx ? [200,head.update({'X-Accel-Redirect' => '/fs' + body.path}),[]] : # Nginx
                         Apache ? [200,head.update({'X-Sendfile' => body.d}),[]] : # Apache
                         (f = Rack::File.new nil; f.instance_variable_set '@path', body.d # Rack
                          f.serving(@r).do{|s,h,b|[s,h.update(head),b]})) :
      [200,head,[body]]}
  end

end
