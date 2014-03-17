watch __FILE__
class R

  ChanRecent = []

  F['/chan/GET'] = -> d,e {
    e.q['set'] = 'chan' if %w{/ /chan}.member? d.pathSegment
    e.q['view'] ||= 'chan'
    nil} # just add some ambient configuration

  F['/chan/POST'] = -> d,e{
    req = Rack::Request.new d.env
    p = req.params
    puts p
    content = p['content']
    if content && !content.empty?
      name = p['title'].do{|t|t.gsub /[?#\s\/]/,'_'} || ''
      uri = '/' + Time.now.iso8601[0..18].gsub('-','/') + name
      if p['file']
        puts (p['file'].class)
      end
      [303,{'Location' => uri},[]]
    end}

  F['set/chan'] = -> d,r,m {
    s = F['set/depth'][R['/chan'],r,m]
    s.push '/chan'.R
    puts s
    s}

  F['view/chan'] = -> d,e {
    br = '<br>'
    post = {_: :form, method: :POST,
      c: [{_: :input, title: :title, name: :title, size: 32},br,
          {_: :textarea, rows: 8, cols: 32, name: :content},br,
          {_: :input, type: :file, name: :file},
          {_: :input, type: :submit, value: 'post '}
         ]}

    [post]
  }

end
