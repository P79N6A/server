# coding: utf-8
#watch __FILE__

module Rack
  module Adapter
    def self.guess _; :rack end
    def self.load _
      Rack::Builder.new {
        use Rack::Deflater
        run R
      }.to_app
    end
  end
end

class R

  # help debug-output through thin/foreman shell-buffering a bit
  $stdout.sync = true
  $stderr.sync = true

  def R.dev # scan watched-files for changes
    Watch.each{|f,ts|
      if ts < File.mtime(f)
        load f
      end }
  end

  def R.call e
    method = e['REQUEST_METHOD']
    return [405, {'Allow' => Allow},[]] unless AllowMethods.member? method
    e.extend Th # environment util-functions
    dev         # check for updated source-code
    e['HTTP_X_FORWARDED_HOST'].do{|h|e['SERVER_NAME']=h} # canonical hostname
    e['SERVER_NAME'] = e.host.gsub /[\.\/]+/, '.'        # clean hostname
    rawpath = URI.unescape(e['REQUEST_PATH'].utf8).gsub(/\/+/,'/') rescue '/' # clean path
    path = Pathname.new(rawpath).expand_path.to_s        # interpret path
    path += '/' if path[-1] != '/' && rawpath[-1] == '/' # preserve trailing-slash
    resource = R[e.scheme + "://" + e.host + path]       # resource reference
    e['uri'] = resource.uri                              # add normalized-URI to environment
    e[:Links] = {}; e[:Response] = {}; e[:filters] = []  # init HEAD storage
    resource.setEnv(e).send(method).do{|s,h,b| # do request and inspect response
      R.log e,s,h,b # log
      [s,h, b]} # return
  rescue Exception => x
    E500[x,e]
  end

  def R.log e, s, h, b
    Stats[:status][s] ||= 0
    Stats[:status][s] += 1
    Stats[:host][e.host] ||= 0
    Stats[:host][e.host] += 1
    mime = nil
    h['Content-Type'].do{|ct|
      mime = ct.split(';')[0]
      Stats[:format][mime] ||= 0
      Stats[:format][mime] += 1}
    puts [e['REQUEST_METHOD'], s,
          [e.scheme, '://', e.host, e['REQUEST_URI']].join,
          h['Location'] ? ['->',h['Location']] : nil, '<'+e.user+'>', e.format, #e['HTTP_ACCEPT'],
          e['HTTP_REFERER']].
          flatten.compact.map(&:to_s).map(&:to_utf8).join ' '
  end

#  GET['/500'] = -> resource, environment {0/0}

  GET['/ERROR'] = -> d,e {
    uri = d.path
    graph = {uri => Errors[uri]}
    [200,{'Content-Type' => e.format},
     [Render[e.format].do{|p|p[graph,e]} || graph.toRDF(d).dump(RDF::Writer.for(:content_type => e.format).to_sym)]]}

  E404 = -> base, env, graph=nil {
    graph ||= {}
    graph[env.uri] ||= {'uri' => env.uri, Type => R[BasicResource]}
    graph[env.uri][RDFs+'seeAlso'] = []
    base.cascade.reverse.map{|p|
      p.e && graph[env.uri][RDFs+'seeAlso'].push(p)}
    ENV2RDF[env, graph]
    graph[env.uri][Type] = R[HTTP+'404']
    [404,{'Content-Type' => env.format},
     [Render[env.format].do{|fn|fn[graph,env]} ||
      graph.toRDF(base).dump(RDF::Writer.for(:content_type => env.format).to_sym, :prefixes => Prefixes)]]}

  ViewGroup[HTTP+'404'] = -> graph, env {
    [{c: 404, style: 'font-size:11em'}, ViewGroup[BasicResource][graph,env]]}

  ViewGroup[HTTP+'500'] = -> graph, env {
    [{c: 500, style: 'font-size:11em;color:red'}, ViewGroup[BasicResource][graph,env]]}

  E500 = -> x,e {
    ENV2RDF[e,graph={}]
    errorURI = '/ERROR/' + e.uri.h
    error = graph[e.uri]
    error[Type] = R[HTTP+'500']
    error[Title] = [x.class, x.message.noHTML].join ' '
    error[Content] = '<pre><h2>stack</h2>' + x.backtrace.join("\n").noHTML + '</pre>'
    Errors[errorURI] = error

    Stats[:status][500] ||= 0
    Stats[:status][500]  += 1
    Stats[:error][errorURI]||= 0
    Stats[:error][errorURI] += 1

    $stderr.puts [500,e.uri,e.R.join(errorURI)].join(' ')
    [500,{'Content-Type' => e.format},
     [Render[e.format].do{|p|p[graph,e]} ||
      graph.toRDF.dump(RDF::Writer.for(:content_type => e.format).to_sym)]]}

  GET['/stat'] = -> e,r { g = {}
    r.q['sort'] ||= 'stat:size'

    Stats.map{|sym, table|
      group = e.uri + '#' + sym.to_s
      g[group] = {'uri' => group,
                  Type => R[Container], Label => sym.to_s,
                  LDP+'contains' => table.map{|key, count|
                    uri = case sym
                          when :error
                            key
                          when :host
                            r.scheme + "://" + key + '/'
                          when :format
                            'http://www.iana.org/assignments/media-types/' + key
                          when :status
                            W3 + '2011/http-statusCodes#' + key.to_s
                          else
                            e.uri + '#' + rand.to_s.h
                          end
                  {'uri' => uri, Title => key, Stat+'size' => count }}}}

    # enumerate schemes
    https =  r.scheme[-1]=='s'
    g['#scheme'] = {'uri' => '#scheme', Type => R[Container],
                    LDP+'contains' => [
                      {'uri' => r.scheme + "://" + r.host + '/stat',
                       Title => r.scheme,
                       Size => Stats[:status].values.inject(0){|s,v|s+v}
                      },
                      {'uri' => (https ? 'http' : 'https') + "://" + r.host + '/stat',
                       Title => https ? 'http' : 'https',
                       Size => 0 }]}

    # free space
    g['#storage'] = {
         Type => R[BasicResource],
      Content => ['<pre>',
                  `df -TBM -x tmpfs -x devtmpfs`,
                  '</pre>']}

    # render
    [200,{'Content-Type' => r.format}, [Render[r.format].do{|p|p[g,r]} ||
      g.toRDF(e).dump(RDF::Writer.for(:content_type => r.format).to_sym)]]}

  ENV2RDF = -> env, graph { # environment -> graph
    # request resource
    subj = graph[env.uri] ||= {'uri' => env.uri, Type => R[BasicResource]}

    # headers
    [env,env[:Links],env[:Response]].compact.map{|fields|
      fields.map{|k,v|
        subj[HTTP+k.to_s.sub(/^HTTP_/,'')] = v.class==String ? v.hrefs : v unless k.to_s.match /^rack/
      }}}

  ViewGroup[Profile] = ViewGroup[SIOC+'Usergroup'] = TabularView
  ViewGroup[Key] = ViewGroup['http://xmlns.com/wot/0.1/PubKey'] = -> g,env { g.map{|u,r| ViewA[Key][r,env]}}
  ViewA[Key] = -> u,e {{class: :pubkey, c: [{_: :a, class: :pubkey, href: u.uri},u]}}
  
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

module Th

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
  def qs # serialize to query-string
   '?'+map{|k,v|k.to_s+'='+(v ? (CGI.escape [*v][0].to_s) : '')}.intersperse("&").join('')
  end
end
