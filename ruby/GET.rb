class R
  
  Apache = ENV['apache']
  Nginx  = ENV['nginx']

  def GET
    if reqFn = @r.q['y'].do{|r| F['req/'+r] }
      # bespoke handler
      reqFn[self,@r]

    elsif file = [self,pathSegment].compact.find(&:f)

      # file exists. check if client or server want it transformed to another MIME
      a = @r.accept.values.flatten
      accepted = a.empty? || (a.member? file.mimeP) || (a.member? '*/*')
      (!accepted || MIMEcook[file.mimeP] || @r.q.has_key?('view')) ?
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

  def resource
    # bubble up full-hostname then path tree until handled
    pathSegment.do{|path|
      lambdas = path.cascade.map{|p| p.uri.t + 'GET' }
      ['http://'+@r['SERVER_NAME'],""].map{|h| lambdas.map{|p|
          F[h + p].do{|fn| fn[self,@r].do{|r|
              $stdout.puts [r[0],'http://'+@r['SERVER_NAME']+@r['REQUEST_URI'],@r['HTTP_USER_AGENT'],@r['HTTP_REFERER']].join ' '
              return r
            }}}}}
    response
  end

  def response
    m = {} # init Model
    g = @r.q['graph']
    graph = (g && F['graph/' + g] || F['graph/'])[self,@r.q,m] # Model identifier

    return F[E404][self,@r] if m.empty?

    @r['ETag'] = [@r.q['view'].do{|v|F['view/'+v] && v}, graph, @r.format].h # View identifier
    
    condResponse @r.format, ->{ # lazy response-finisher
      m.values.map{|r|(r.env env).graphFromFile m if r.class == R } # expand graph
      m.delete_if{|u,r|r.class == R} # wipe unexpanded thunks
      render @r.format, m, @r} # model -> view
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
