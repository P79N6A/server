# coding: utf-8
watch __FILE__

module Rack
  module Adapter
    # don't guess, use rack
    def self.guess _; :rack end
    def self.load _ # Rack configuration
      Rack::Builder.new {
        use Rack::Deflater # gzip response
        run R              # call R.call
      }.to_app
    end
  end
end

class R

  # coax debug-output through thin/foreman shell-buffering a bit
  $stdout.sync = true
  $stderr.sync = true

  def R.dev # scan watched-files for changes
    Watch.each{|f,ts|
      if ts < File.mtime(f)
        load f
      end }
  end

  def R.call e # Rack calls request here
    method = e['REQUEST_METHOD']

    # whitelist supported methods in Allow constant
    return [405, {'Allow' => Allow},[]] unless AllowMethods.member? method

    # add environment utility-functions to rack env-Hash
    e.extend Th

    # "development mode" hook, source-code watch
    dev

    # find canonical hostname
    e['HTTP_X_FORWARDED_HOST'].do{|h|
      e['SERVER_NAME']=h}

    # strip junk in hostname, like .. and /
    e['SERVER_NAME'] = e.host.gsub /[\.\/]+/, '.'

    # local paths can contain URI special-cars
    rawpath = URI.unescape(e['REQUEST_PATH'].utf8).gsub(/\/+/,'/') rescue '/'

    # interpret path, preserving trailing-slash
    path = Pathname.new(rawpath).expand_path.to_s
    path += '/' if path[-1] != '/' && rawpath[-1] == '/'

    # affix found URI to environment
    resource = R[e.scheme + "://" + e.host + path]
    e['uri'] = resource.uri

    # init response-header fields
    e[:Links] = {}
    e[:Response] = {}
    e[:filters] = []

    # call request-method
    resource.setEnv(e).send(method).do{|s,h,b|
      # inspect response
      R.log e,s,h,b

      # return
      [s,h,b]
    }
  rescue Exception => x
    E500[x,e]
  end

  def R.log e, s, h, b
    return unless e&&s&&h&&b
    Stats['status'][s.to_s] ||= {'uri' => '/stat/status/'+s.to_s, Size => 0}
    Stats['status'][s.to_s][Size] += 1
    Stats['host'][e.host] ||= {'uri' => e.host, Size => 0}
    Stats['host'][e.host][Size] += 1

    # log request to stdout
    puts [e['REQUEST_METHOD'], s, [e.scheme, '://', e.host, e['REQUEST_URI']].join,
          h['Location'] ? ['->',h['Location']] : nil, '<'+e.user+'>', e.format, e['HTTP_REFERER']].
          flatten.compact.map(&:to_s).map(&:to_utf8).join ' '
  end

  E404 = -> base, env, graph=nil {
    graph ||= {}
    graph[env.uri] ||= {'uri' => env.uri, Type => R[BasicResource]}
    seeAlso = graph[env.uri][RDFs+'seeAlso'] = []

    # add container-container breadcrumbs
    base.cascade.reverse.map{|p|
      p.e && seeAlso.push(p)}

    # add incomplete-path matches
    seeAlso.concat base.a('*').glob
    
    ENV2RDF[env, graph]
    graph[env.uri][Type] = R[HTTP+'404']
    [404,{'Content-Type' => env.format},
     [Render[env.format].do{|fn|fn[graph,env]} ||
      graph.toRDF(base).dump(RDF::Writer.for(:content_type => env.format).to_sym, :prefixes => Prefixes)]]}

  ViewGroup[HTTP+'404'] = -> graph, env {
    [{_: :style, c: "tr[property='http://www.w3.org/2011/http#USER_AGENT'] td {font-size:.8em}"},
     ({_: :a, class: :addButton, c: '+', href: '?new'} if env.editable),
     ViewGroup[BasicResource][graph,env]]}

  GET['/500'] = -> resource, environment {0/0} # force an error to see what happens

  ViewGroup[HTTP+'500'] = -> graph, env {
    [{_: :style, c: 'body {background-color:red}'},
     ViewGroup[BasicResource][graph,env]]}

  E500 = -> x,e {
    slug = e.uri.h
    uri = '/stat/HTTP/500/' + slug
    error = Stats['HTTP']['500'][slug] = {
      'uri' => uri,
      DC+'source' => e.uri,
      Type => R[HTTP+'500'],
#      SIOC+'has_container' => R['/stat/HTTP/500'],
      Title => [x.class,x.message.noHTML].join(' '),
      Content => '<pre>' + x.backtrace.join("\n").noHTML + '</pre>'}

    graph = {uri => error}
    [500,{'Content-Type' => e.format},[Render[e.format].do{|p|p[graph,e]} || graph.toRDF.dump(RDF::Writer.for(:content_type => e.format).to_sym)]]}

  GET['/stat'] = -> e,r {
    path = e.path
    cursor = Stats
    path.sub(/^\/stat\//,'').split('/').map{|part|
      
    }

    g = {path => Stats[path]}

    # render response
    [200,{'Content-Type' => r.format}, [Render[r.format].do{|p|p[g,r]} || g.toRDF(e).dump(RDF::Writer.for(:content_type => r.format).to_sym)]]}

  ViewGroup[Profile] = ViewGroup[SIOC+'Usergroup'] = TabularView
  
  ViewGroup[User] = -> g,env {
    if env.signedIn
      g.map{|u,r|
        {style: "border-radius: 2em; background-color:#eee;color:#000;display:inline-block",
         c: [{_: :a, class: :user, style: "font-size: 3em;text-decoration:none",
              href: "http://linkeddata.github.io/profile-editor/#/profile/view?webid=" + CGI.escape(u)}, # enhanced profile-view
             ViewA[BasicResource][r,env]]}}
    else # no WebID found, link to cert-creator
      {_: :h2, c: {_: :a, c: 'Sign In', href: 'http://linkeddata.github.io/signup/'}}
    end}

  GET['/whoami'] = -> e,r {
    if r.scheme!='https'
      r.SSLupgrade
    else
      u = r.user.uri # user URI,  <dns:IP> or WebID
      m = {u => {'uri' => u, Type => R[User]}}
      r[:Response]['ETag'] = u.h
      r[:Response]['Content-Type'] = r.format + '; charset=UTF-8'
      e.condResponse ->{
        Render[r.format].do{|p|p[m,r]}|| m.toRDF.dump(RDF::Writer.for(:content_type => r.format).to_sym, :standard_prefixes => true, :prefixes => Prefixes)}
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

  def allowWrite
    true
  end

  def q; @r.q end

end

module Th # methods which introspect request-environment

  def user
    @user ||= (user_WebID || user_DNS)
  end

  def signedIn
    @signedIn ||= user.uri.match /^http/
  end

  def user_WebID
    x509cert.do{|c|
      cert = R['/cache/uid/' + R.dive(c.h)]
      verifyWebID.do{|id| cert.w id } unless cert.exist?
      return R[cert.r] if cert.exist?}
  end

  def verifyWebID pem = x509cert
    if pem
      OpenSSL::X509::Certificate.new(pem).do{|x509|
        x509.extensions.find{|x|x.oid == 'subjectAltName'}.do{|user|
          user = user.value.sub /^URI./, ''
          head = {'Accept' => 'text/turtle, text/n3, application/ld+json;q=0.8, text/html;q=0.5, application/xhtml+xml;q=0.5, application/rdf+xml;q=0.3'}
          graph = RDF::Repository.load user, headers: head
          query = "PREFIX : <http://www.w3.org/ns/auth/cert#> SELECT ?m ?e WHERE { <#{user}> :key [ :modulus ?m; :exponent ?e; ] . }"
          SPARQL.execute query, graph do |result|
            if x509.public_key.n.to_i == result[:m].value.to_i(16)
              user.R.n3.w graph.dump(:n3) # cache user info locally
              return user
            else
              puts "modulus mismatch for #{user}"
            end
          end}}
    end
    nil
  rescue Exception => x
    puts [:verifyWebID,uri,x,x.class, x.message].join(' ')
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

  def q # parse query-string
    @q ||=
      (if q = self['QUERY_STRING']
         h = {}
         q.split(/&/).map{|e| k, v = e.split(/=/,2).map{|x| CGI.unescape x }
                              h[k] = v }
         h
       else
         {}
       end)
  end

end

class Hash
  def qs # serialize query-string
    '?'+map{|k,v|
      k.to_s + '=' + (v ? (CGI.escape [*v][0].to_s) : '')
    }.intersperse("&").join('')
  end
end
