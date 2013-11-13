class E

  def GET
    # bespoke handler ||
    # raw file ||
    # resource
    if reqFn = F['req/'+@r.q['y']]
      reqFn[self,@r]
    elsif file = [self,pathSegment].compact.find(&:f)
      a = @r.accept.values.flatten
      accepted = a.empty? || (a.member? file.mimeP) || (a.member? '*/*')
      (@r.q.has_any_key(%w{format view}) ||
       MIMEcook[file.mimeP] || !accepted) ? resource : (file.env @r).getFile
    else
      resource
    end
  end

  def getFile
    @r['ETag'] = [m,size].h
    maybeSend mimeP,->{self},:link
  end

  def resource
    # bubble up site then global tree until handled (false return-value to pass)
    pathSegment.do{|path|
      lambdas = path.cascade.map{|p| p.uri.t + 'GET' }
      ['http://'+@r['SERVER_NAME'],""].map{|h| lambdas.map{|p|
          F[h + p].do{|fn| fn[self,@r].do{|r| return r}}}}}
    
    # default handler
    response
  end

  def send?
    !((m=@r['HTTP_IF_NONE_MATCH']) && m.strip.split(/\s*,\s*/).include?(@r['ETag']))
  end
  
  def maybeSend m,b,lH=false
    # agent need this version?
    send? ?
    # continue
    b[].do{|b|
      # response metadata
      h = {'Content-Type'=> m,
           'ETag'=> @r['ETag']}
      h.update({'Cache-Control' => 'no-transform'}) if m.match /^(audio|image|video)/
      h.update({'Link' => '<' + (URI.escape uri) + '?format=text/n3>; rel=meta'}) if lH

      b.class == E ? (Nginx ?                                                     # nginx enabled
                      [200,h.update({'X-Accel-Redirect' => '/fs' + b.path}),[]] : # Nginx file-handler
                      Apache ?                                              # Apache enabled
                      [200,h.update({'X-Sendfile' => b.d}),[]] :   # Apache file-handler
                      (r = Rack::File.new nil                      # Rack file-handler
                       r.instance_variable_set '@path',b.d
                       r.serving(@r).do{|s,m,b|[s,m.update(h),b]})
                      ) :
      [200, h, b]} : # normal (unaccelerated) response
      [304,{},[]]    # client has response version
  end

end
