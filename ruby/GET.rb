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
    pathSegment.do{|path| # bubble up tree at http://host/path first, then /path (matching all hosts)
      lambdas = path.cascade.map{|p| p.uri.t + 'GET' }
      ['http://'+@r['SERVER_NAME'],""].map{|h| lambdas.map{|p|
          F[h + p].do{|fn| fn[self,@r].do{|r|
              $stdout.puts [r[0],'http://'+@r['SERVER_NAME']+@r['REQUEST_URI'],@r['HTTP_USER_AGENT'],@r['HTTP_REFERER']].join ' '
              return r
            }}}}}
    response
  end

  def response
    q = @r.q # querystring
    m = {'#' => {'uri' => '#',
                  Type => R[HTTP+'Response']}}

    set = (q['set'].do{|s| F['set/'+s]} ||
                           F['set'])[self,q,m]

    return F[404][self,@r] if !set || set.empty?
    # response identity
    @r['ETag'] = [q['view'].do{|v|F['view/'+v] && v}, # view
                  set.sort.map{|r|[r, r.m]},          # resource version(s)
                  @r.format].h                        # response MIME

    condResponse @r.format, ->{
      set.map{|r|r.env(@r).toGraph m} # expand set
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
