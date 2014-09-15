watch __FILE__

class R

  GET['/whoami'] = -> d,e { # direct to user URI
    e.user.do{|u|[303,{'Location'=>u.uri},[]]}}

  LoginForm = {_: :form, action: '/login', method: :POST,
      c: [{_: :input, name: :user, placeholder: :username},
          {_: :input, name: :passwd, type: :password, placeholder: :password},
          {_: :input, type: :submit, value: :login}]}

  GET['/login'] = -> e,r {
    graph = {e.uri => {'uri' => e.uri, Content => H(LoginForm)}}
    [200, {'Content-Type' => r.format + '; charset=UTF-8'},
     [Render[r.format][graph,r]]]}

  POST['/login'] = -> e,r {
    puts "hi"
    h = {}
    Rack::Utils.set_cookie_header!(h, "user", {:value => "asdf", :path => "/"})
    [200,h,[]]
  }

end

module Th

  def user # URI | nil
    user_webid || user_basic || nil
  end

  def user_basic

    
    
  end

end
