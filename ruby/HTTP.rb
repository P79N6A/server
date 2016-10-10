# coding: utf-8
#watch __FILE__

module Rack
  module Adapter
    # we always use the rack-interface, with this config
    def self.guess _; :rack end
    def self.load _
      Rack::Builder.new {
        use Rack::Deflater # gzip response
        run R              # call R.call
      }.to_app
    end
  end
end

class R

  AllowMethods = %w{HEAD GET PUT PATCH POST OPTIONS DELETE}
  Allow = AllowMethods.join ', '
 
  def OPTIONS
    ldp
    method = @r['HTTP_ACCESS_CONTROL_REQUEST_METHOD']
    headers = @r['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']
    head = {'Access-Control-Allow-Methods' => (AllowMethods.member? method) ? method : Allow}
    head['Access-Control-Allow-Headers'] = headers if headers
    [200,(@r[:Response].update head), []]
  end

  def HEAD
    self.GET.
    do{| s, h, b |
       [ s, h, []]} # just HEADer
  end

  def setEnv r
    @r = r
    self
  end

  def getEnv; @r end
  alias_method :env, :getEnv

  ENV2RDF = -> env, graph {
    subj = graph[env.uri] ||= {'uri' => env.uri}
    qs = graph['#query'] = {'uri' => '#query'}
    env.q.map{|key,val|
      qs['#'+key.gsub(/\W+/,'_')] = val}
    [env, env[:Links], env[:Response]].compact.map{|db|
      db.map{|k,v|
        subj[HTTP+k.to_s.sub(/^HTTP_/,'')] = v.class==String ? v.noHTML : v unless k.to_s.match /^rack/ }}}

  def ldp
    @r[:Links][:acl] = aclURI
    @r[:Response].update({
      'Accept-Patch' => 'application/ld+patch, application/sparql-update',
      'Accept-Post'  => 'application/ld+json, application/x-www-form-urlencoded, text/turtle',
      'Access-Control-Allow-Credentials' => 'true',
      'Access-Control-Allow-Origin' => @r['HTTP_ORIGIN'].do{|o|(o.match HTTP_URI) && o } || '*',
      'Access-Control-Expose-Headers' => "User, Location, Link, Vary, Last-Modified",
      'Allow' => Allow,
      'MS-Author-Via' => 'SPARQL',
      'User' => [@r.user],
      'Vary' => 'Accept,Accept-Datetime,Origin,If-None-Match',
    })
    self
  end

  # coax output through thin/foreman/shell buffers
  $stdout.sync = true
  $stderr.sync = true

  def R.dev # scan watched-files for changes
    Watch.each{|f,ts|
      if ts < File.mtime(f)
        load f
      end }
  end

  def R.call e # Rack calls resource
    method = e['REQUEST_METHOD']

    # allowable methods over HTTP
    return [405,{'Allow' => Allow},[]] unless AllowMethods.member? method
    return [400,{},[]] if e['REQUEST_PATH'].match(/\.php$/i)

    # bind environment utility-functions
    e.extend Th

    # load changed source-code
    dev

    # preserve canonical hostname in proxy scenario
    e['HTTP_X_FORWARDED_HOST'].do{|h|
      e['SERVER_NAME']=h}

    # clean-up hostname
    e['SERVER_NAME'] = e.host.gsub /[\.\/]+/, '.'

    # interpret path
    rawpath = URI.unescape(e['REQUEST_PATH'].utf8).gsub(/\/+/,'/')
    path = Pathname.new(rawpath).expand_path.to_s
    # preserve trailing-slash
    path += '/' if path[-1] != '/' && rawpath[-1] == '/'

    # resource URI
    resource = R[e.scheme + "://" + e.host + path]
    e['uri'] = resource.uri

    # header-field containers
    e[:Links] = {}
    e[:Response] = {}
    e[:filters] = []

    # call resource
    resource.setEnv(e).send(method).do{|s,h,b|
      # inspect response
      R.log e,s,h,b
      [s,h,b]}
  rescue Exception => x
    E500[x,e]
  end

  def R.log e, s, h, b
    return unless e && s && h && b
    Stats['status'][s.to_s] ||= {'uri' => '/stat/status/'+s.to_s.t, Type => R[Resource], Size => 0}
    Stats['status'][s.to_s][Size] += 1
    Stats['host'][e.host] ||= {'uri' => e.scheme+'://'+e.host, Label => e.host, Size => 0}
    Stats['host'][e.host][Size] += 1

    puts [e['REQUEST_METHOD'], s, [e.scheme, '://', e.host, e['REQUEST_URI']].join,
          h['Location'] ? ['->',h['Location']] : nil, '<'+e.user+'>', e.format, e['HTTP_REFERER'], e['HTTP_USER_AGENT']].
          flatten.compact.map(&:to_s).map(&:to_utf8).join ' '
  end

  def R.parseQS qs
    h = {}
    qs.split(/&/).map{|e|
      k, v = e.split(/=/,2).map{|x| CGI.unescape x }
      h[(k||'').downcase] = v }
    h
  end

  E404 = -> base, env, graph=nil {
    graph ||= {}
    user = env.user.to_s
    graph[user] = {'uri' => user, Type => R[FOAF+'Person']}
    graph[env.uri] ||= {'uri' => env.uri, Type => R[BasicResource]}
    seeAlso = graph[env.uri][RDFs+'seeAlso'] = []

    # containment
    base.cascade.reverse.map{|p|
      p.e && seeAlso.push(p)}

    ENV2RDF[env, graph]
    [404,{'Content-Type' => env.format},
     [Render[env.format].do{|fn|fn[graph,env]} ||
      graph.toRDF(base).dump(RDF::Writer.for(:content_type => env.format).to_sym, :prefixes => Prefixes)]]}

  ViewGroup[HTTP+'500'] = -> graph, env {
    [{_: :style, c: 'body {background-color:red}'},
     ViewGroup[BasicResource][graph,env]]}

  E500 = -> x,e {
    errors = Stats['status']['500']

    error = errors[e.uri.h] ||= {
      'uri' => '//' + e.host + e['REQUEST_URI'],
      Type => R[HTTP+'500'],
      Label => [x.class,x.message.noHTML].join(' '),
      Content => '<pre>' + x.backtrace.join("\n").noHTML + '</pre>',
      Size => 0}

    error[Size] += 1

    graph = {'' => error}
    [500,{'Content-Type' => e.format},[Render[e.format].do{|p|p[graph,e]} || graph.toRDF.dump(RDF::Writer.for(:content_type => e.format).to_sym)]]}

  GET['/stat'] = -> e,r {
    graph = {}
    x = Stats # tree
    e.path.sub(/^\/stat\//,'').split('/').map{|name|
      n = x[name]  # try name
      x = n if n } # found

    if x.uri # leaf
      graph[x.uri] = x
    else # container
      x.keys.map{|child|
        uri = x[child]['uri']  || (e.uri.t + child.t)
        graph[uri] = {'uri' => uri,
                      Type => R[x[child].uri ? Resource : Container],
                      Size => x[child][Size] || x[child].keys.size,
                      Label => x[child][Label],
                      Content => x[child][Content],
                     }
      }
    end

    graph['..'] = {'uri' => '..', Type => R[Container]}
    e.q['sort'] ||= 'stat:size'
    e.q['reverse'] ||= true
    # render response
    [200,{'Content-Type' => r.format}, [Render[r.format].do{|p|p[graph,r]} || graph.toRDF(e).dump(RDF::Writer.for(:content_type => r.format).to_sym)]]}
  
  ViewGroup[User] = -> g,env {
    if env.signedIn
      g.map{|u,r|
        {style: "border-radius: 2em; background-color:#eee;color:#000;display:inline-block",
         c: [{_: :a, class: :user, style: "font-size: 3em;text-decoration:none",
              href: "http://linkeddata.github.io/profile-editor/#/profile/view?webid=" + CGI.escape(u)}, # 3rd-party profile UI
             ViewA[BasicResource][r,env]]}}
    else # no WebID found, link to onboarding-UI
      {_: :h2, c: {_: :a, c: 'Sign In', href: 'http://linkeddata.github.io/signup/'}}
    end}

  def aclURI
    if basename.index('.acl') == 0
      self
    elsif hierPart == '/'
      child '.acl'
    else
      dir.child '.acl.' + basename
    end
  end

  def allowRead
    true
  end

  def q; @r.q end

end

module Th # methods on request-environment

  def accept; @accept ||= accept_ end

  def accept_ k=''
    d={}
    self['HTTP_ACCEPT'+k].do{|k|
      (k.split /,/).map{|e| # each pair
        f,q = e.split /;/   # split MIME from q value
        i = q && q.split(/=/)[1].to_f || 1.0 # q || default
        d[i] ||= []; d[i].push f.strip}} # append
    d
  end

  def linkHeader
    lh = {}
    self['HTTP_LINK'].do{|links|
      links.split(', ').map{|link|
        uri,rel = nil
        link.split(';').map{|a|
          a = a.strip
          if a[0] == '<' && a[-1] == '>'
            uri = a[1..-2]
          else
            rel = a.match(/\s*rel="?([^"]+)"?/)[1]
          end
        }
        lh[rel] = uri }}
    lh
  end

  def user
    @user ||= (user_WebID || user_DNS)
  end

  def signedIn
    @signedIn ||= user.uri.match /^http/
  end

  def user_WebID
    x509cert.do{|c|
      cert = R['/cache/uid/' + R.dive(c.h)] # cert URI
      verifyWebID.do{|id| cert.w id } unless cert.exist? # update cache
      return R[cert.r] if cert.exist?} # validated user-URI
  end

  def verifyWebID pem = x509cert
    if pem
      OpenSSL::X509::Certificate.new(pem).do{|x509|
        x509.extensions.find{|x|x.oid == 'subjectAltName'}.do{|user|
          user = user.value.sub /^URI./, ''
          head = {'Accept' => 'text/turtle, application/ld+json;q=0.8, text/html;q=0.5, application/xhtml+xml;q=0.5, application/rdf+xml;q=0.3'}
          graph = RDF::Repository.load user, headers: head
          query = "PREFIX : <http://www.w3.org/ns/auth/cert#> SELECT ?m ?e WHERE { <#{user}> :key [ :modulus ?m; :exponent ?e; ] . }"
          SPARQL.execute query, graph do |result|
            if x509.public_key.n.to_i == result[:m].value.to_i(16)
              user.R.ttl.w graph.dump(:ttl) # cache user-info
              return user
            else
              puts "modulus mismatch for #{user}"
            end
          end}}
    end
    nil
  end

  def x509cert
    self['rack.peer_cert'].do{|v|
      p = v.split /[\s\n]/
      return [p[0..1].join(' '),
              p[2..-3],
              p[-2..-1].join(' ')].join "\n" unless p.size < 5 }
    nil
  end

  def user_DNS
    addr = self['HTTP_ORIGIN_ADDR'] || self['REMOTE_ADDR'] || '0.0.0.0'
    R['dns:' + addr]
  end

  def SSLupgrade; [301,{'Location' => "https://" + host + self['REQUEST_URI']},[]] end

  def q # memoize key/vals
    @q ||=
      (if q = self['QUERY_STRING']
         R.parseQS q
       else
         {}
       end)
  end

end

class Hash
  def qs # serialize to query-string
    '?'+map{|k,v|
      k.to_s + '=' + (v ? (CGI.escape [*v][0].to_s) : '')
    }.intersperse("&").join('')
  end
end
