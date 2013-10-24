watch __FILE__
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
    send? ? # agent already has this version?
    b[].do{|b| # prepare response
      h = {'Content-Type'=> m, 'ETag'=> @r['ETag']} # response header
      m.match(/^(audio|image|video)/) &&            # media MIME-type?
      h.update({'Cache-Control' => 'no-transform'}) # no further compression
      h.update({'MS-Author-Via' => 'DAV, SPARQL'})  # authoring
      lH && h.update({'Link' => '<' + (URI.escape uri) + '?format=text/n3>; rel=meta'})
      b.class == E ? (Nginx ?                                                     # nginx enabled
                      [200,h.update({'X-Accel-Redirect' => '/fs' + b.path}),[]] : # Nginx file-handler
                      Apache ?                                              # Apache enabled
                      [200,h.update({'X-Sendfile' => b.d}),[]] :   # Apache file-handler
                      (r = Rack::File.new nil                      # create Rack file-handler
                       r.instance_variable_set '@path',b.d         # set path
                       r.serving(@r).do{|s,m,b|[s,m.update(h),b]}) # Rack file-handler
                      ) :
      [200, h, b]} : # response
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

  def GET_resource
    handleReq  = F[ 'req/' + @r.q['y'] ]
    handlePath = F[@r['REQUEST_PATH'].t+('GET')]
    handleURI  = F[ uri.t + ('GET') ]
    (handleReq||handlePath||handleURI).do{|y|y[self,@r]} ||
    as('index.html').do{|i| i.e && # HTML index
      ((uri[-1]=='/') ? i.env(@r).GET_file : # index in dir
       [301, {Location: uri.t}]  )} ||       # rebase to index dir
    response # resource handler
  end
  
  # HTTP response
  def response

    q = @r.q       # query-string
    g = q['graph'] # graph-function selector

    # empty response graph
    m = {}

    # identify graph
    graphID = (F['protograph/' + g] || F['protograph/']).do{|p|p[self,q,m]}

    return F[E404][self,@r] if m.empty?

    # identify response
    @r['ETag'] ||= [graphID, q, @r.format, Watch].h

    maybeSend @r.format, ->{
      
      # response
      r = E'/E/req/' + @r['ETag'].dive
      if r.e # response exists
        r    # cached response
      else
        
        # graph
        c = E '/E/graph/' + graphID.dive
        if c.e # graph exists
          m.merge! c.r true
        else
          # build graph
          (F['graph/' + g] || F['graph/']).do{|f| f[self,q,m]}
          # cache graph
          c.w m,true
        end

        # graph sort/filter
        E.filter q, m, self

        # cache response
        r.w render @r.format, m, @r
      end }
  end
  
end
