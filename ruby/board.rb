watch __FILE__
class R

  BoardRecent = []

  F['/board/GET'] = -> d,e {
    e.q['set'] = 'board' if %w{/ /board}.member? d.pathSegment
    e.q['view'] ||= 'board'
    nil} # just add some ambient configuration

  F['/board/POST'] = -> d,e{
    p = (Rack::Request.new d.env).params
    content = p['content']
    if content && !content.empty?
      host = 'http://' + e['SERVER_NAME']
      path = Time.now.iso8601[0..18].gsub('-','/') + ( p['title'].do{|t|t.gsub /[?#\s\/]/,'_'} || '' )
      uri = host + '/' + path

      # post as Hash+JSON
      post = {
        'uri' => uri,
        Type => R[SIOCt+'BoardPost'],
        Content => content,
      }
      p['title'].do{|t| post[Title] = t}

      # optional attachment
      file = p['file']
      if file && file[:type].match(/^image/)
        basename = file[:filename]
        puts file
      end

      # save
      R[uri].jsonDoc.w({uri => post},true)
      
      [303,{'Location' => uri},[]]
    else
      [303,{'Location' => d.uri},[]]
    end}

  F['set/board'] = -> d,r,m {
    s = F['set/depth'][R['/board'],r,m]
    s.push '/board'.R
    puts s
    s}

  F['view/board'] = -> d,e {
    br = '<br>'
    post = {_: :form, method: :POST, enctype: "multipart/form-data",
      c: [{_: :input, title: :title, name: :title, size: 32},br,
          {_: :textarea, rows: 8, cols: 32, name: :content},br,
          {_: :input, type: :file, name: :file},
          {_: :input, type: :submit, value: 'post '}
         ]}

    [post]
  }

end
