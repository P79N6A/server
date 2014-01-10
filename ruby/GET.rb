class E
  
  Apache = ENV['apache']
  Nginx  = ENV['nginx']

  def GET
    if reqFn = @r.q['y'].do{|r| F['req/'+r] }
      # bespoke handler
      reqFn[self,@r]

    elsif file = [self,pathSegment].compact.find(&:f)

      # file exists, but client might not accept its MIME, or want it transformed to another MIME
      a = @r.accept.values.flatten
      accepted = a.empty? || (a.member? file.mimeP) || (a.member? '*/*')
      (@r.q.has_any_key(%w{format view}) || MIMEcook[file.mimeP] || !accepted) ?
       resource : (file.env @r).getFile

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
          F[h + p].do{|fn| fn[self,@r].do{|r|
              $stdout.puts [r[0],'http://'+@r['SERVER_NAME']+@r['REQUEST_URI'],@r['HTTP_USER_AGENT'],@r['HTTP_REFERER']].join ' '
              return r
            }}}}}
    response
  end

  def send?
    !((m=@r['HTTP_IF_NONE_MATCH']) && m.strip.split(/\s*,\s*/).include?(@r['ETag']))
  end
  
  def maybeSend m, b, iR = false; c = 200
    send? ?            # does agent have this version?
    b[].do{|b|         # continue with response

      h = {'Content-Type'=> m,
           'ETag'=> @r['ETag']}

      h.update({'Cache-Control' => 'no-transform'}) if m.match /^(audio|image|video)/ # already compresed
      h.update({'Link' => '<' + @r['uri'] + '?view>; rel=meta'}) if iR     # link to description
      h.update({'MS-Author-Via' => 'SPARQL'})  # authoring preference

      # frontend-specific response handlers
      b.class == E ? (Nginx ?                                                   # nginx chosen?
                      [c,h.update({'X-Accel-Redirect' => '/fs' + b.path}),[]] : # Nginx handler
                      Apache ?                                                  # Apache chosen?
                      [c,h.update({'X-Sendfile' => b.d}),[]] : # Apache handler
                      (r = Rack::File.new nil                  # Rack handler
                       r.instance_variable_set '@path',b.d     # configure Rack response
                       r.serving(@r).do{|s,m,b|[(s == 200 ? c : s),m.update(h),b]})) :
      [c, h, b]} : # normal response
      [304,{},[]]  # client has response
  end

end
