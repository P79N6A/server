# -*- coding: utf-8 -*-
class E

  def GET
    a=@r.accept.values.flatten                         # if a file exists
    send(f ? (if (@r.q.has_any_key(['format','graph','view']) || # request a specific view
                 (MIMEcook[mime] && !@r.q.has_key?('raw')) ||    # some MIMEs have a default view
                 !(a.empty?||a.member?(mime)||a.member?('*/*'))) # view if MIME not accepted
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
      b.class == E ? (r = Rack::File.new nil # use Rack file server
                      r.instance_variable_set '@path',b.d # at path
                     (r.serving @r).do{|s,m,b|[s,m.update(h),b]}) : # Rack file-handler
      [200, h, b]} : # normal response
      [304,{},[]] # unmodified
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
     ).do{|y|y.(self,@r)} ||# custom handler
    as('index.html').do{|i| # HTML indexes
      i.e && # exists?
      ((uri[-1]=='/') ? i.env(@r).GET_file : # inside dir?
       [301, {Location: uri.t}]  )} ||  # redirect to dir
    resources # resource handler
  end

  # resource set -> response
  def resources m={}
    if g = F['graph/'+@r.q['graph']] # custom graph
      g[self,@r.q,m]
    else
      (if s = F['set/'+@r.q['set']] # custom set
         s[self,@r.q,m]
       else # default set
         docs.concat (d? && uri[-1]=='/') ? c : []
       end).map{|u| m[u.uri] ||= u} # populate set
    end # at least a graph skeleton should exist, else 404
    m.empty? ? (Fn 'req/'+HTTP+'404',self,@r) : # empty set -> 404
    (s=m.sort.map{|u,r|[u,r.respond_to?(:m)&&r.m]}.h # Set identifier
     @r['ETag']=[s,@r.q,@r.format].h # response identifier ((uri,mtime),querystring,format)
     maybeSend @r.format,->{ # does agent have resource ?
       r=E'/E/req/'+@r['ETag'].dive  # cached response
       r.e && r ||                   # cached response -> response
       (g ||( # custom graph, or:
        c = E '/E/graph/'+s.dive     # cached graph
        c.e && m.merge!(c.r(true))|| # cached graph -> graph
        (m.values.map{|r|r.env(@r).graphFromFile m} # Set -> graph
         c.w m,true))        # graph -> cache
        E.filter @r.q, m       # env -> graph -> graph
        v=render @r.format, m, @r # graph -> response
        r.w v; [v])})          # response -> cache
  end

end
