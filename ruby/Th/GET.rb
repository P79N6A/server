#watch __FILE__
class E

  def GET
    f = [self,       # path & domain
         pathSegment # path, all domains
        ].find{|f| f.f }

    if f
       a = @r.accept.values.flatten
    view = @r.q.has_any_key %w{format view}
    cook = MIMEcook[f.mimeP] && !@r.q.has_key?('raw')
  accept = a.empty? || (a.member? f.mimeP) || (a.member? '*/*')

 (view || cook || !accept) ? self.GET_resource : f.env(@r).GET_img

    else
      self.GET_resource
    end
  end

  def maybeSend m,b,lH=false
    # agent need this version?
    send? ?
    # continue
    b[].do{|b|
      # response metadata
      h = {
        'Content-Type'=> m,
        'ETag'=> @r['ETag'],
      }.merge @r['Cache']

      # don't compress media MIMEs
      m.match(/^(audio|image|video)/) && h.update({'Cache-Control' => 'no-transform'})

      # Link dataURL for non-hypermedia/RDF payloads
      lH && h.update({'Link' => '<' + (URI.escape uri) + '?format=text/n3>; rel=meta'})

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

  def send?
    !((m=@r['HTTP_IF_NONE_MATCH']) && m.strip.split(/\s*,\s*/).include?(@r['ETag']))
  end  

  def GET_file
    @r['ETag'] = [m,size].h
    maybeSend mimeP,->{self},:link
  end

  def GET_img
   (thumb? ? thumb : self).GET_file
  end

  def pathHandler host, method='GET'
    paths = pathSegment.cascade.map{|path|path.uri.t + method}
    [host,""].map{|host|
      paths.map{|path|
        handler = F[host + path]
        return handler if handler
      }}
    nil
  end

  def GET_resource
    handleReq  = F['req/' + @r.q['y']] # parametric resource-handler
    h = handleReq || (pathHandler 'http://' + @r['SERVER_NAME'])
#    puts "handlr #{h}"
    h ? h[self, @r] : response
  end
  
end
