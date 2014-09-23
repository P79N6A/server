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
    req = Rack::Request.new r
    session = req.cookies['session'].do{|s|Session[s]}
    args = req.params
    username = args['user']
    passwd = args['passwd']
    user = R['/user/' + username.slugify]
    pwI = passwd.crypt salt
    pwR = user['passwd'][0]
    user['passwd'] = pwR = pwI unless pwR # fill crypt
    if pwI == pwR # passwd match
      puts "login successful"
      unless session && session['user'][0] == user
        puts "init session"
        s = rand.to_s.h
        Rack::Utils.set_cookie_header!(headers, "session", {:value => s, :path => "/"})
        Session[s]['user'] = user # session URI -> user URI
      end
    else
      puts "bad password"
    end
    [200,headers,[]]}

  Session = -> id {R['/cache/session/' + (R.dive id)]}

end

module Th

  def user
    user_webid ||
    user_basic ||
    user_ambient
  end

  def user_basic
    (Rack::Request.new self).cookies['session'].do{|sid|
      R::Session[sid]['user'][0]}
  end

  def user_ambient
    R['dns:' + ( self['HTTP_ORIGIN_ADDR'] || self['REMOTE_ADDR'] )]
  end

end
