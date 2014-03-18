watch __FILE__
class R

  BoardRecent = []

  F['/board/GET'] = -> d,e {
    e.q['set'] = 'board' if %w{/ /board}.member? d.pathSegment
    nil}

  F['/board/POST'] = -> d,e{
    p = (Rack::Request.new d.env).params # parse input
    content = p['content']
    if content && !content.empty?
      host = 'http://' + e['SERVER_NAME']
      path = Time.now.iso8601[0..18].gsub(/[-T]/,'/') + '.' + ( p['title'].do{|t|t.gsub /[?#\s\/]/,'_'} || rand.to_s.h[0..3] )
      uri = host + '/' + path

      post = { # post as Hash+JSON
        'uri' => uri,
        Type => R[SIOCt+'BoardPost'],
        Content => F['cleanHTML'][content],
      }
      p['title'].do{|t| post[Title] = t.hrefs}

      # optional attachment
      file = p['file']
      if file && file[:type].match(/^image/)
        basename = file[:filename]
      end

      doc = R[uri].jsonDoc      # doc
      doc.w({uri => post},true) # save
      doc.ln_s R['/index/board/'+uri] # link to timeline
      
      [303,{'Location' => uri},[]]
    else
      [303,{'Location' => d.uri},[]]
    end}

  F['set/board'] = -> r,q,m {
    F['set/depth'][R['/index/board/http://' + r.env['SERVER_NAME']],q,m]}

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
