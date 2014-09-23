watch __FILE__

class R

  GET['/whoami'] = -> d,e {
    [303,{'Location' => e.user.uri},[]]}

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
    salt = 'sel'
    sessionURI = -> id {R['/cache/session/' + (R.dive id)]}
    req = Rack::Request.new r
    arg = req.params
    session = req.cookies['session'].do{|s|sessionURI[s]}
    username = arg['user']
    passwd = arg['passwd']
    user = R['/user/' + username.slugify]
    pwI = passwd.crypt salt
    pwR = user['passwd'][0]
    user['passwd'] = pwR = pwI unless pwR # fill crypt
    if pwI == pwR # passwd match
      unless session && session['user'][0] == user
        s = rand.to_s.h
        Rack::Utils.set_cookie_header!(headers, "session", {:value => s, :path => "/"})
        sessionURI[s]['user'] = user # session URI -> user URI        
      end
    end
    [200,headers,[]]}

end

module Th

  def user
    user_webid ||
    user_basic ||
    user_ambient
  end

  def user_basic
    # cookie UUID -> user URI
    nil
  end

end
