#watch __FILE__

module Th
  FingerprintKeys = %w{HTTP_ACCEPT HTTP_ACCEPT_CHARSET HTTP_ACCEPT_LANGUAGE HTTP_ACCEPT_ENCODING HTTP_USER_AGENT REMOTE_ADDR}
  def uid
    ('/user/'+FingerprintKeys.map{|i|self[i]}.h.dive).E
  end
end

class E

  Name = E FOAF + 'name'

  fn '/whoami/POST',->e,r{
    r.q['name'].do{|n|
      n.size < 88 &&
      (u=r.uid
       u.dp Name
       u[Name] = n )}
    e.GET_resource}

  fn '/whoami/GET',->e,r{ i = r.uid
    H([{_: :a, href: i.uri, c: i.uri},
       {_: :form, method: :post,
        c: ['name ',
         {_: :input, name: :name, value: [*i[Name]][0]}]},
       {_: :dl, c: Th::FingerprintKeys.map{|i|[{_: :dt, c: i},{_: :dd, c: r[i]}]}}]).hR}

end
