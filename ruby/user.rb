watch __FILE__

class R

  GET['/whoami'] = -> d,e {
    e.user.do{|u|[303,{'Location'=>u.uri},[]]}} # direct to user URI

  GET['/login'] = -> e,r {
    graph = RDF::Graph.new
    form = H View['login'][nil,nil]
    puts form
# Rack::Utils.set_cookie_header!(headers, "foo", {:value => "bar", :path => "/"})
    e.condResponse ->{}
  }

  View['login'] = -> d,e {
    {_: :form, action: '/login', method: :POST,
      c: [{_: :input, name: :user, placeholder: :username},
          {_: :input, name: :passwd, type: :password, placeholder: :password}]}}

end

module Th

  def user # URI | nil
    user_webid || user_basic || nil
  end

  def user_basic

    
    
  end

end
