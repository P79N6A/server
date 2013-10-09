watch __FILE__
class E

  def GET
       a = @r.accept.values.flatten
    view = @r.q.has_any_key %w{format view}
    processFile = MIMEcook[mime] && !@r.q.has_key?('raw')
  accept = a.empty? || (a.member? mime) || (a.member? '*/*')
    file = [self, # specific domain + path
#            (E (URI uri).path) # specific path, all domains
           ].find{|f| f.f }
    if file
      if view || processFile || !accept
        self.GET_resource
      else
        file.GET_img
      end
    else
      self.GET_resource
    end
  rescue Exception => x
    $stderr.puts 500,x.message,x.backtrace
    Fn 'backtrace',x,@r
  end

  def maybeSend m,b,lH=false
    send? ? # agent already has this version?
    b.().do{|b| # continue
      h = {'Content-Type'=> m, 'ETag'=> @r['ETag']} # response header
      m.match(/^(audio|image|video)/) &&            # media MIME-type?
      h.update({'Cache-Control' => 'no-transform'}) # no further compression
      h.update({'MS-Author-Via' => 'DAV, SPARQL'})  # authoring
      lH && h.update({'Link' => '<' + (URI.escape uri) + '?format=text/n3>; rel=meta'}) # Link Header - full URI variant
      b.class == E ? (Nginx ?                                                     # nginx env-var
                      [200,h.update({'X-Accel-Redirect' => '/fs' + b.path}),[]] : # Nginx file-handler
                      Apache ?                                              # Apache env-var
                      [200,h.update({'X-Sendfile' => b.d}),[]] : # Apache file-handler
                      (r = Rack::File.new nil                      # create Rack file-handler
                       r.instance_variable_set '@path',b.d         # set path
                       r.serving(@r).do{|s,m,b|[s,m.update(h),b]}) # Rack file-handler
                      ) :
      [200, h, b]} : # response triple
      [304,{},[]]    # not modified
  end

  def send?
    !((m=@r['HTTP_IF_NONE_MATCH']) && m.strip.split(/\s*,\s*/).include?(@r['ETag']))
  end  

  def GET_file
    @r['ETag'] = [m,size].h
    maybeSend mime,->{self},:link
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

  # graph constructor
  fn 'graph/',->e,q,m{
    F['set/' + q['set']][e, q, m]. # doc set
    map{|u|m[u.uri] ||= u}} # resource thunks, response will expand if necessary

  # document-set constructor
  fn 'set/',->d,e,m{
    s = []
    s.concat d.docs
#    s.concat (E (URI d.uri).path).docs # path on all sites
#    puts "set #{s}"
    s }
  
  # default HTTP response
  def response

    # request arguments
    q = @r.q       # query-string
    g = q['graph'] # graph-generation function selector

    # request graph 
    m = {}

    # add resources to request graph 
    F['graph/' + g][self,q,m]

    # empty graph -> 404
    return F[E404][self,@r] if m.empty?

    # inspect request-graph
    if q.has_key? 'debug'
      puts "docs #{m.keys.join ' '}"
      puts "resources #{m['frag']['res']}" if m['frag']
    end

    # request-graph identifier
    s = (q.has_key?('nocache') ? rand.to_s :  # random identifier
         m.sort.map{|u,r|[u, r.respond_to?(:m) && r.m]}).h # canonicalized set signature

    # response identifier
    @r['ETag'] ||= [s, q, @r.format].h

    # check if client has response
    maybeSend @r.format, ->{
      
      # cached response identifier
      r = E'/E/req/' + @r['ETag'].dive
      
      if r.e # response already generated
        r    # cached response
      else
        
        # cached graph identifier
        c = E '/E/graph/' + s.dive

        if c.e # cached graph exists
          m.merge! c.r true # read cache
        else
          # construct response graph
          m.values.map{|r|
            r.env(@r).graphFromFile m}

          # cache response graph
          c.w m,true
        end

        # response graph sorting/filtering
        E.filter q, m, self

        # response body
        r.w render @r.format, m, @r
      end }
  end
  
end
