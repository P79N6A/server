#watch __FILE__

module Th

  def user
    @user ||= (user_WebID || user_words || user_DNS)
  end

  def user_WebID
    x509cert.do{|c|
      cert = ('/cache/uid/' + (R.dive c.h)).R
      verifyWebID.do{|id| cert.w id } unless cert.exist?
      return cert.r.R if cert.exist?} 
  end

  def verifyWebID pem = cert
    if pem
      OpenSSL::X509::Certificate.new(pem).do{|x509|
        x509.extensions.find{|x|x.oid == 'subjectAltName'}.do{|user|
          user = user.value.sub /^URI./, ''
          graph = RDF::Repository.load user
          query = "PREFIX : <http://www.w3.org/ns/auth/cert#> SELECT ?m ?e WHERE { <#{user}> :key [ :modulus ?m; :exponent ?e; ] . }"
          SPARQL.execute query, graph do |result|
            if x509.public_key.n.to_i == result[:m].value.to_i(16)
              return user
            else
              puts "modulus mismatch for #{user}"
            end
          end}}
    end
    nil
  end

  def x509cert
    (self['HTTP_SSL_CLIENT_CERT']||
     self['rack.peer_cert']).do{|v|
      p = v.split /[\s\n]/
      return [p[0..1].join(' '),
              p[2..-3],
              p[-2..-1].join(' ')].join "\n" unless p.size < 5 }
    nil
  end

  def cookies
    (Rack::Request.new self).cookies
  end

  def session
    cookies['session-id'].do{|s|R::Session[s]}
  end

  def user_words
    session.do{|s|s['user'][0]}
  end

  def user_DNS
    addr = self['HTTP_ORIGIN_ADDR'] || self['REMOTE_ADDR']
    R['dns:' + addr]
  end

end

class R

  LoginForm = {_: :form, action: '/login', method: :POST,
      c: [{_: :input, name: :user, placeholder: :username},
          {_: :input, name: :passwd, type: :password, placeholder: :password},
          {_: :input, type: :submit, value: :login}]}

  GET['/whoami'] = -> e,r {
    u = r.user.uri
    m = {u => {'uri' => u, Type => R[FOAF+'Person']}}
    r[:Response]['ETag'] = u.h
    e.condResponse ->{Render[r.format][m,r]}}

  GET['/login'] = -> e,r {
    uid = r.user.uri
    content = if uid.match /^dns:/
                LoginForm
              else 
                [{_: :h3, c: {_: :a, href: uid, c: uid }}, ' ',
                 {_: :a, href: '/logout', c: 'log out', style: 'border: .1em dotted; padding: .2em; font-size: 1.1em'}]
              end
    graph = {e.uri => {'uri' => e.uri, Content => H(content)}}
    [200, {'Content-Type' => r.format + '; charset=UTF-8'}, [Render[r.format][graph,r]]]}

  GET['/logout'] = -> e,r {
    r.session.do{|s|
      s['user'] = nil}
    [303, {'Location' => '/'}, []]}

  Session = -> id {R['/cache/session/' + (R.dive id)]}

  POST['/login'] = -> e,r {
    head = {'Location' => '/'}
    args = Rack::Request.new(r).params
    name = args['user'].slugify[0..32]
    user = R['/user/' + name.h[0..2] + '/' + name + '#' + name]
    shadow = R['/index' + user.uri]
    pwI = args['passwd'].crypt 'sel'      # claimed
    pwR = shadow['passwd'][0]             # actual
    unless pwR                            # init user
      user.jsonDoc.
        w({user.uri => {DC+'created' => Time.now.iso8601}},true)
      shadow['passwd'] = pwR = pwI
    end
    if pwI == pwR                       # passwd valid?
      head['Location'] = user.uri
      session_id = rand.to_s.h
      Session[session_id]['user'] = user
      Rack::Utils.set_cookie_header!(head, "session-id", {:value => session_id, :path => "/"})
      
    end
    [303,head,[]]}

  ViewGroup[FOAF+'Person'] = -> d,e {
    d.map{|uri, person|{_: :a, class: :person, href: uri, c: [person[Name],' ']}}}

  ViewGroup[FOAF+'Group'] = -> d,e {
    [{_: :style, c: "
.foaf {float: right; background-color: #111; color: #ccc; margin-bottom: .2em}
.foaf > a {background-color:#000; color: #fff; font-size: 1.25em; margin: .2em}
"}, {class: :foaf, c: d.map{|id, group|[{_: :a, href: id, c: group.R.fragment}, group[Name], '<br>']}}]}

end
