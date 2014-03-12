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
    maybeSend mimeP,->{self}
  end

  def resource
    # bubble up full-hostname then path tree until handled
    pathSegment.do{|path|
      lambdas = path.cascade.map{|p| p.uri.t + 'GET' }
      ['http://'+@r['SERVER_NAME'],""].map{|h| lambdas.map{|p|
          F[h + p].do{|fn| fn[self,@r].do{|r|
              $stdout.puts [r[0],'http://'+@r['SERVER_NAME']+@r['REQUEST_URI'],@r['HTTP_USER_AGENT'],@r['HTTP_REFERER'],@r.format].join ' '
              return r
            }}}}}
    response
  end

  def response

    m = {} # model

    # Model identity
    g = @r.q['graph']
    graphID = (g && F['graph/' + g] || F['graph/'])[self,@r.q,m]

    return F[E404][self,@r] if m.empty?

    # View identity
    @r['ETag'] ||= [@r.q['view'].do{|v|F['view/' + v] && v}, graphID, @r.format, Watch].h
    
    maybeSend @r.format, ->{# finish response if needed
      m.values.map{|r|(r.env env).graphFromFile m if r.class == R } # expand model
      m.delete_if{|u,r|r.class == R} # cleanup unexpanded thunks
      render @r.format, m, @r} # view
  end

  def send?
    !((m=@r['HTTP_IF_NONE_MATCH']) && m.strip.split(/\s*,\s*/).include?(@r['ETag']))
  end
  
  def maybeSend m, b
    send? ?
    b[].do{|b| # continue
      h = {'Content-Type'=> m, 'ETag'=> @r['ETag']}
      h.update({'Cache-Control' => 'no-transform'}) if m.match /^(audio|image|video)/ # already compresed

      # frontend-specific handlers
      b.class == R ? (Nginx ?  [200,h.update({'X-Accel-Redirect' => '/fs' + b.path}),[]] : # Nginx handler
                      Apache ? [200,h.update({'X-Sendfile' => b.d}),[]] : # Apache handler
                      (r = Rack::File.new nil # Rack handler
                       r.instance_variable_set '@path', b.d
                       r.serving(@r).do{|s,m,b|[s,m.update(h),b]})) :
      [200,h,[b]]} : # normal response
      [304,{},[]] # client has response
  end

end
