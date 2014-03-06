watch __FILE__
class R

  # https://github.com/linkeddata/ldphp/blob/master/www/inc/webid.lib.php

  F['/whoami/GET'] = -> d,e {
    e['HTTP_SSL_CLIENT_CERT'].do{|v|
      p = v.split /[\s\n]/ # linebreaks sometimes converted to spaces upstream
      pem = [p[0..1].join(' '),p[2..-3],p[-2..-1].join(' ')].join "\n"
      x509 = OpenSSL::X509::Certificate.new pem
      pubkey = x509.public_key
      subject = nil
      x509.extensions.find{|x|x.oid=='subjectAltName'}.do{|altName|
        subject = altName.value.sub /^URI:/, ''}
      m = pubkey.n
      e = pubkey.e
    }
    nil }
  
end
