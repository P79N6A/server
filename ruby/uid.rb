# coding: utf-8
#watch __FILE__
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

end

class R

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

  ViewGroup[Profile] = ViewGroup[SIOC+'Usergroup'] = TabularView
  ViewGroup[Key] = ViewGroup['http://xmlns.com/wot/0.1/PubKey'] = -> g,env { g.map{|u,r| ViewA[Key][r,env]}}
  ViewA[Key] = -> u,e {{class: :pubkey, c: [{_: :a, class: :pubkey, href: u.uri},u]}}
  
  ViewGroup[User] = -> g,env {
    if env.signedIn # render user-data
      g.map{|u,r|
        {style: "border-radius: 2em; background-color:#eee;color:#000;display:inline-block",
         c: [{_: :a, class: :user, style: "font-size: 3em",
              href: "http://linkeddata.github.io/profile-editor/#/profile/view?webid=" + CGI.escape(u)},
             ViewA[BasicResource][r,env]]}}
    else # no WebID found, offer cert-creation service
      {_: :h2, c: {_: :a, c: 'Sign In', href: 'http://linkeddata.github.io/signup/'}}
    end}

end
