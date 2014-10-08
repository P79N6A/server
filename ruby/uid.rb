module Th

  def user
    @user ||= (webIDuser || userDNS)
  end

  def webIDuser
    x509cert.do{|c|
      cert = ('/cache/uid/' + (R.dive c.h)).R
      webIDverify.do{|id| cert.w id } unless cert.exist?
      return cert.r.R if cert.exist?} 
  end

  def webIDverify pem = cert
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

  def userDNS
    addr = self['HTTP_ORIGIN_ADDR'] || self['REMOTE_ADDR']
    R['dns:' + addr]
  end

end
