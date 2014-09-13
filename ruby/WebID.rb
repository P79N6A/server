module Th

  def user_webid
    if c = cert
      u = ('/cache/uid/' + (R.dive c.h)).R # cache URI
      webID.do{|id| u.w id} if !u.e # check cert
      return u.r.R if u.e # user URI if found
    end
    nil
  end

  def webID pem = cert # match cert with web claim
    if pem
      OpenSSL::X509::Certificate.new(pem).do{|x509| # parse
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

  def cert # peel cert out of request, unmunge linebreaks
    self['HTTP_SSL_CLIENT_CERT'].do{|v|
      p = v.split /[\s\n]/
      return [p[0..1].join(' '), p[2..-3], p[-2..-1].join(' ')].join "\n" unless p.size < 5}
    nil
  end

end
