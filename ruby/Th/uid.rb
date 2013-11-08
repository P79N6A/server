#watch __FILE__

module Th
  FingerprintKeys = %w{
   HTTP_ACCEPT
   HTTP_ACCEPT_CHARSET
   HTTP_ACCEPT_LANGUAGE
   HTTP_ACCEPT_ENCODING
   HTTP_USER_AGENT
   HTTP_ORIGIN_ADDR
   REMOTE_ADDR
}

  def uid
    ('/u/'+FingerprintKeys.map{|i|self[i]}.h.dive).E
  end
end

class E

  fn '/whoami/GET',->e,r{
    [302,{Location: '/@'+r.uid.uri},[]]}

  fn 'http://www.facebook.com/GET',->e,r{
    H[{_: :a, href: e.uri, c: e.uri}].hR}


end
