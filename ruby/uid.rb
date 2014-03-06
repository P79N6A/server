watch __FILE__
class R

  F['/whoami/GET'] = -> d,e {
    e['HTTP_SSL_CLIENT_CERT'].do{|pem|
      x509 = OpenSSL::X509::Certificate.new pem
      pubkey = x509.public_key
       puts pubkey
     }
  }

end
