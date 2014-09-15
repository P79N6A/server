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
    headers = {}
    user = r.user
    puts "user #{user}"
    Rack::Utils.set_cookie_header!(headers, "user", {:value => "", :path => "/"})
    [200,headers,[]]}

end

module Th

  def user # URI | nil
    user_webid || user_basic || nil
  end

  def user_basic
    puts "webID cert missing/invalid, trying POSTed credentials"
    # account is previously unknown, create it with supplied passwd

    # check password

    puts qs
    
  end

end
