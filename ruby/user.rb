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

    arg = Rack::Request.new(r).params
    username = arg['user']
    passwd = arg['passwd']
    user = R['/user/' + username.slugify]

    pwI = passwd.crypt salt
    pwR = user['passwd'][0]

    user['passwd'] = pwR = pwI unless pwR # account previously unseen, claim it

    if pwI == pwR # match
      s = R['/cache/session/' + (R.dive rand.to_s.h)] # session URI
      s['username'] = user
      Rack::Utils.set_cookie_header!(headers, "session", {:value => s.uri, :path => "/"})
    else
      # fail
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
