watch __FILE__
class R

  ChanRecent = []

  F['/chan/GET'] = -> d,e {
    e.q['set'] = 'chan' if %w{/ /chan}.member? d.pathSegment
    e.q['view'] ||= 'chan'
    nil} # just add some ambient configuration

  F['set/chan'] = -> d,r,m {
    s = F['set/depth'][R['/chan'],r,m]
    s.push '/chan'.R
    puts s
    s}

  F['view/chan'] = -> d,e {
    br = '<br>'
    post = {_: :form, method: :POST,
      c: [{_: :input, title: :title, name: :title, size: 32},br,
          {_: :textarea, rows: 8, cols: 32,name: :title},br,
          {_: :input, type: :file},
          {_: :input, type: :submit, value: 'post '}
         ]}

    [post]
  }

end
