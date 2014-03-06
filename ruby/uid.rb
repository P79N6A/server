watch __FILE__
class R

  F['/whoami/GET'] = -> d,e {
    e['HTTP_SSL_CLIENT_CERT'].do{|pem|
       puts pem
     } || puts('no id!')
  }

end
