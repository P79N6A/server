watch __FILE__
class R

  GET['/whoami'] = -> d, e { r = nil
    e.cert.do{|pem|
      OpenSSL::X509::Certificate.new(pem).do{|x509| # parse
        x509.extensions.find{|x|x.oid == 'subjectAltName'}.do{|user|
          user = user.value.sub /^URI./, ''
          graph = RDF::Repository.load user
          query = "PREFIX : <http://www.w3.org/ns/auth/cert#> SELECT ?m ?e WHERE { <#{user}> :key [ :modulus ?m; :exponent ?e; ] . }"
          SPARQL.execute query, graph do |result|
            if x509.public_key.n.to_i == result[:m].value.to_i(16)
              r = [302,{'Location'=>user},[]]
            end
          end}}}
  r }

end

module Th

  def cert
    self['HTTP_SSL_CLIENT_CERT'].do{|v|
      p = v.split /[\s\n]/
      unless p.size < 5
        p = [p[0..1].join(' '), # header
             p[2..-3],          # body
             p[-2..-1].join(' ')].join "\n" # format
        puts p
        p
      else
        nil
      end}
  end

end
