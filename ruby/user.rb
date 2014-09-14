watch __FILE__

class R

  GET['/whoami'] = -> d,e { # direct to user URI
    e.user.do{|u|[303,{'Location'=>u.uri},[]]}}

  GET['/login'] = -> e,r {
    graph = RDF::Graph.new
    form = H View['login'][nil,nil]
    puts form
    h = {}
    Rack::Utils.set_cookie_header!(h, "user", {:value => "asdf", :path => "/"})
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
