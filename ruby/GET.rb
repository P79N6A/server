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

    m = {} # TODO request-model as RDF::Graph, benchmark vs our pickle-able JSON graphs, + write persistable RDF::Repository class of similar performance

    # Model
    g = @r.q['graph'] # model identity
    graphID = (g && F['protograph/' + g] || F['protograph/'])[self,@r.q,m]

    return F[E404][self,@r] if m.empty? # protograph empty - nothing found

    # View
    @r['ETag'] ||= [@r.q['view'].do{|v|F['view/' + v] && v}, graphID, @r.format, Watch].h

    maybeSend @r.format, ->{
      r = R '/cache/view/' + @r['ETag'].dive
      if r.e # view exists?
        r
      else
        c = R '/cache/model/' + graphID.dive
        if c.e # model exists?
          m = c.r true
        else
          (g && F['graph/' + g] || F['graph/'])[self, @r.q,m]
          c.w m,true # model -> cache
        end
        r.w render @r.format, m, @r # view -> cache
      end }
  end

  def send?
    !((m=@r['HTTP_IF_NONE_MATCH']) && m.strip.split(/\s*,\s*/).include?(@r['ETag']))
  end
  
  def maybeSend m, b; c = 200
    send? ?
    b[].do{|b| # continue
      h = {'Content-Type'=> m, 'ETag'=> @r['ETag']}
      h.update({'Cache-Control' => 'no-transform'}) if m.match /^(audio|image|video)/ # already compresed

      # frontend-specific handlers
      b.class == R ? (Nginx ?                                                   # nginx chosen?
                      [c,h.update({'X-Accel-Redirect' => '/fs' + b.path}),[]] : # Nginx handler
                      Apache ?                                                  # Apache chosen?
                      [c,h.update({'X-Sendfile' => b.d}),[]] : # Apache handler
                      (r = Rack::File.new nil                  # Rack handler
                       r.instance_variable_set '@path',b.d     # configure Rack response
                       r.serving(@r).do{|s,m,b|[(s == 200 ? c : s),m.update(h),b]})) :
      [c, h, b]} : # normal response
      [304,{},[]]  # client has response
  end

  fn '/GET',->e,r{
    x = 'index.html'
    i = [e,e.pathSegment].compact.map{|e|e.as x}.find &:e # file exists
    if i && !r['REQUEST_URI'].match(/\?/) # querystring implies up-to-date query
      if e.uri[-1] == '/' # inside dir?
        i.env(r).fileGET  # show index
      else
        [301, {Location: e.uri.t}, []] # descend into dir
      end
    else
      if r['REQUEST_URI'].match(/\/index.html$/) # request an index
        r.format
        e.parent.env(r).response
      else
        e.response
      end
    end}

end
