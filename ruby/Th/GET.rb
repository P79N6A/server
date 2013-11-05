watch __FILE__
class E

  def GET
    if reqFn = F['req/'+@r.q['y']]
      reqFn[self,@r]
    elsif file = [self,pathSegment].compact.find(&:f)
      a = @r.accept.values.flatten
      accepted = a.empty? || (a.member? file.mimeP) || (a.member? '*/*')
      (@r.q.has_any_key %w{format view} ||
       MIMEcook[file.mimeP] || !accepted) ? getPath : (file.env @r).getFile
    else
      getPath
    end
  end

  def getPath
    h = pathHandler 'http://' + @r['SERVER_NAME']
    h ? h[self, @r] : response
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

  def getFile
    @r['ETag'] = [m,size].h
    maybeSend mimeP,->{self},:link
  end

end
