class E

  def GET
    a=@r.accept.values.flatten                         # if a file exists
    send(f ? (if (@r.q.has_any_key(['format','graph','view']) || # request a specific view
                 (MIMEcook[mime] && !@r.q.has_key?('raw')) ||    # some MIMEs have a default view
                 !(a.empty?||a.member?(mime)||a.member?('*/*'))) # render acceptable view if file MIME not accepted
                 :GET_resource # invoke resource handler
              else
                :GET_img # continue to file handler
              end) :
         :GET_resource)
  rescue Exception => x
    Fn 'backtrace',x,@r
  end

  def maybeSend m,b
    send? ? # agent already has this version?
    b.().do{|b| # continue
      h = {'Content-Type'=> m, 'ETag'=> @r['ETag']} # populate response header
      m.match(/^(audio|image|video)/) && h.update({'Cache-Control' => 'no-transform'}) # media files are compressed
      b.class == E ? (r = Rack::File.new nil                        # create Rack file-handler
                      r.instance_variable_set '@path',b.d           # set path
                     (r.serving @r).do{|s,m,b|[s,m.update(h),b]}) : # Rack file-handler
      [200, h, b]} : # normal response
      [304,{},[]]    # not modified
  end

  def send?
    !((m=@r['HTTP_IF_NONE_MATCH']) && m.strip.split(/\s*,\s*/).include?(@r['ETag']))
  end  

  def GET_file
    @r['ETag'] = [m,size].h
    maybeSend mime,->{self}
  end

  def GET_img
   (thumb? ? thumb : self).GET_file
  end

  def GET_resource                 # for 
    (F['req/'+@r.q['y']] ||           # all URIs 
     F[@r['REQUEST_PATH'].t+('GET')]||# all hostnames, specific path
     F[uri.t+('GET')]                 # specific URI
     ).do{|y|y.(self,@r)} ||       # custom handler
    as('index.html').do{|i|        # HTML index
      i.e &&                       #  exists?
      ((uri[-1]=='/') ? i.env(@r).GET_file : # are we inside dir?
       [301, {Location: uri.t}]  )} ||       # rebase to index dir
    response
  end

  # graph constructor
  fn 'graph/',->e,q,m{
    F['set/' + q['set']][e, q, m]. # doc set
    map{|u|m[u.uri] ||= u}}

  # document set constructor
  fn 'set/',->d,e,m{d.docs}
  
  # construct HTTP response
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

    # request-graph identifier
    s = (q.has_key?('nocache') ? rand.to_s :  # random identifier
         m.sort.map{|u,r|[u, r.respond_to?(:m) && r.m]}).h # each modification time

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
        E.filter q, m

        # construct response body
        v = render @r.format, m, @r

        # cache response body
        r.w v

        # response body
        [v]
      end }
  end
  
end
