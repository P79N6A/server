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

  fn 'graphID/',->e,q,g{
    puts "graphID #{e.uri}"
    set = F['set/' + q['set']][e,q,g]

    # resource URIs to graph
    set.map{|u| g[u.uri] ||= u }

    F['graphID'][g]}

  fn 'graphID',->g{
    g.sort.map{|u,r|
      [u, r.respond_to?(:m) && r.m]}.h}

  fn 'graph/',->e,q,m{
    puts "graph #{e.uri} #{m.keys}"
    m.values.map{|r|
      # expand resource-pointers to graph
      (r.env e.env).graphFromFile m if r.class == E }}

  # document-set constructor
  fn 'set/',->e,q,_{
    s = []
    s.concat e.docs
    s.concat e.pathSegment.docs # path on all domains
    puts "set #{s}" if q.has_key? 'debug'
    s }
  
  # HTTP response
  def response

    # request arguments
    q = @r.q       # query-string
    g = q['graph'] # graph-generation function selector

    # response graph
    m = {}

    # identify requested graph 
    graph = F['graphID/'+g].do{|i|i[self,q,m]}
    graph = rand.to_s.h if q.has_key? 'nocache'

    # inspect request
    #if q.has_key? 'debug'
      puts "docs #{m.keys.join ' '}"
      puts "resources #{m['frag']['res']}" if m['frag']
      puts "graphID #{graph}"
    #end

    # empty graph -> 404
    return F[E404][self,@r] if m.empty?

    # response identifier
    @r['ETag'] ||= [graph, q, @r.format].h

    maybeSend @r.format, ->{
      
      # cached response
      r = E'/E/req/' + @r['ETag'].dive
      
      if r.e # response already generated
        r    # cached response
      else
        
        # cached graph
        c = E '/E/graph/' + graph.dive

        if c.e # graph already generated
          m.merge! c.r true # cached graph
        else
          puts "build"
          # build graph
          (F['graph/' +g] || F['graph/']).do{|f| f[self,q,m]}

          # cache graph
          c.w m,true
        end

        # response graph sorting/filtering
        E.filter q, m, self

        # cache response
        r.w render @r.format, m, @r
      end }
  end
  
end
