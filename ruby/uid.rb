watch __FILE__
class R

  F['/whoami/GET'] = -> d,e {
    e['HTTP_SSL_CLIENT_CERT'].do{|pem|
      lines = pem.split ' '
      head = lines[0..1].join ' '
      foot = lines[-2..-1].join ' '
      body = lines[2..-3].join "\n"
      pem = [head,body,foot].join "\n"
      x509 = OpenSSL::X509::Certificate.new pem
      pubkey = x509.public_key
      puts pubkey
     }
  }

end
