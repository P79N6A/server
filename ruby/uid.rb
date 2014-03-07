watch __FILE__
class R

  # https://github.com/linkeddata/ldphp/blob/master/www/inc/webid.lib.php

  F['/whoami/GET'] = -> d,e {
    e['HTTP_SSL_CLIENT_CERT'].do{|v|
      p = v.split /[\s\n]/ # linebreaks sometimes munged into spaces upstream
      unless p.size < 2
        pem = [p[0..1].join(' '),p[2..-3],p[-2..-1].join(' ')].join "\n" # reformat
        OpenSSL::X509::Certificate.new(pem).do{|x509|
          x509.extensions.find{|x|x.oid == 'subjectAltName'}.do{|altName|
            uri = altName.value.sub /^URI:/, ''
            pubkey = x509.public_key
            m = pubkey.n
            e = pubkey.e
            graph = RDF::Repository.load(uri)
            query = "PREFIX : <http://www.w3.org/ns/auth/cert#> SELECT ?m ?e WHERE { <#{uri}> :key [ :modulus ?m; :exponent ?e; ] . }"
            r = SPARQL.execute query,graph
            puts r
          }
        }
      end
    }
    nil
  }
  
end
