#watch __FILE__
class R

  # concept via https://github.com/linkeddata/ldphp/blob/master/www/inc/webid.lib.php

  F['/whoami/GET'] = -> d,e { response = nil

    e['HTTP_SSL_CLIENT_CERT'].do{|v|

      p = v.split /[\s\n]/ # linebreaks sometimes munged into spaces upstream

      unless p.size < 5

        pem = [p[0..1].join(' '), # header
               p[2..-3],          # body
               p[-2..-1].join(' ')].join "\n" # format

        OpenSSL::X509::Certificate.new(pem).do{|x509| # parse

          x509.extensions.
          find{|x|x.oid == 'subjectAltName'}.do{|altName| # user URI
            uri = altName.value.sub /^URI:/, ''
            pubkey = x509.public_key
            m = pubkey.n # modulus
            e = pubkey.e # exponent
            graph = RDF::Repository.load uri
            query = "PREFIX : <http://www.w3.org/ns/auth/cert#> SELECT ?m ?e WHERE { <#{uri}> :key [ :modulus ?m; :exponent ?e; ] . }"
            SPARQL.execute query, graph do |result|
              mCert = m.to_i
              mWeb = result[:m].value.to_i 16
              if mCert == mWeb
                response = [302,{'Location'=>uri},[]]
              end
            end}}
      end}
    response }

end
