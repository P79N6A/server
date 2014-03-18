watch __FILE__
class R

  BoardRecent = []

  F['/board/GET'] = -> d,e {
    e.q['set'] = 'board' if %w{/ /board}.member? d.pathSegment
    e.q['view'] ||= 'board'
    nil} # just add some ambient configuration

  F['/forum/GET'] = F['/board/GET']

  F['/board/POST'] = -> d,e{
    p = (Rack::Request.new d.env).params
    content = p['content']
    if content && !content.empty?
      host = 'http://' + e['SERVER_NAME']
      path = Time.now.iso8601[0..18].gsub(/[-T]/,'/') + '.' + ( p['title'].do{|t|t.gsub /[?#\s\/]/,'_'} || rand.to_s.h[0..3] )
      uri = host + '/' + path

      # post as Hash+JSON
      post = {
        'uri' => uri,
        Type => R[SIOCt+'BoardPost'],
        Content => F['cleanHTML'][content],
      }
      p['title'].do{|t| post[Title] = t.hrefs}

      # optional attachment
      file = p['file']
      if file && file[:type].match(/^image/)
        basename = file[:filename]
#        puts (file.methods - Object.methods)
      end

      doc = R[uri].jsonDoc      # JSON
      doc.w({uri => post},true) # save
      doc.ln_s R['/index/board/'+uri] # link to timeline
      
      [303,{'Location' => uri},[]]
    else
      [303,{'Location' => d.uri},[]]
    end}

  F['set/board'] = -> d,r,m {
    s = F['set/depth'][R['/board'],r,m]
    s.push '/board'.R
    puts s
    s}

  F['view/'+SIOCt+'BoardPost'] = -> d,e {
    posts = d.resourcesOfType SIOCt+'BoardPost'
    posts.map{|post|
      {class: :boardPost, style: 'float: right; border: .1em dotted #ccc',
        c: [post[Title].do{|t|{_: :h3, c: t}},
            post[Content]
           ]}
    }
  }

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
