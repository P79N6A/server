# coding: utf-8
module Th

  def user
    @user ||= (user_WebID || user_DNS)
  end

  def signedIn
    user.uri.match /^http/
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
      u = r.user.uri
      m = {u => {'uri' => u, Type => R[User]}}
      r[:Response]['ETag'] = u.h
      r[:Response]['Content-Type'] = r.format + '; charset=UTF-8'
      e.ldp.condResponse ->{
        Render[r.format].do{|p|p[m,r]}|| m.toRDF.dump(RDF::Writer.for(:content_type => r.format).to_sym, :standard_prefixes => true, :prefixes => Prefixes)}
    end}

  ViewGroup[User] = -> g,env {
    if env.signedIn
      g.map{|u,r|ViewA[User][r,env]}
    else
      {_: :h2, c: {_: :a, c: 'Sign In', href: 'http://linkeddata.github.io/signup/'}}
    end}

  ViewA[User] = -> u,e {
    [{_: :h1, c: u[Name]},
     {_: :a, style: "font-size: 2em;color:#fff;background-color:#000;text-decoration:none", href: u.uri, c: u.uri},
     ViewA[Resource][u,e]]}

  ViewGroup[FOAF+'Person'] = ViewGroup[SIOC+'Usergroup'] = TabularView

end
