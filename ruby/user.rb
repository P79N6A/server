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

  GET['/logout'] = -> e,r {
    r.session.do{|s|
      s['user'] = nil}
    [303, {Location: '/'}, []]}

  POST['/login'] = -> e,r {
    hdr = {}
    args = Rack::Request.new(r).params
    name = args['user'].slugify[0..32]
    user = R['/user/' + name.h[0..2] + '/' + name + '#' + name]
    shadow = R['/index' + user.uri]
    pwI = args['passwd'].crypt 'sel'      # claimed
    pwR = shadow['passwd'][0]             # actual
    unless pwR                            # new user
      user.jsonDoc.
        w({user.uri => {DC+'created' => Time.now.iso8601}},true)
      shadow['passwd'] = pwR = pwI
    end
    if pwI == pwR                         # passwd valid?
      unless user == r.user_basic         # session exists
        s = rand.to_s.h                   # new session-ID
        Rack::Utils.set_cookie_header!(hdr, "session", {:value => s, :path => "/"}) # return session-ID
        Session[s]['user'] = user # link to user URI
      end
    end
    [200,hdr,[]]}

  Session = -> id {R['/cache/session/' + (R.dive id)]}

end

module Th

  def user
    user_webid ||
    user_basic ||
    user_ambient
  end

  def session
    cookies['session'].do{|s|
      R::Session[s]}
  end

  def user_basic
    session.do{|s|s['user'][0]}
  end

  def user_ambient
    R['dns:' + ( self['HTTP_ORIGIN_ADDR'] || self['REMOTE_ADDR'] )]
  end

end
