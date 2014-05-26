watch __FILE__
class R

  GET['/forum'] = -> r,e {
    path = r.justPath.uri.sub(/^\/forum\/*/,'/').tail
    if path.match(/^[^\/]*\/?$/) # root or child thereof
      if path.empty? # sub index
        e.q['view'] ||= 'table'
        r.descend.setEnv(e).response
      else # sub
        e.q['set'] = 'page'
        e.q['view'] ||= 'subforum'
        e['forum'] = path
        nil
      end
    else
      nil
    end}

  POST['/forum'] = -> d,e{
    ps = d.path.sub(/^\/forum/,'').tail.split '/'
    sub = ps[0]
    p = (Rack::Request.new d.env).params
    title = p['title']
    content = p['content']
    if sub && content && !content.empty?
      date = Time.now.iso8601
      if ps.size == 1 # new thread
        name = p['title'].do{|t|t.gsub /[?#\s\.\/]+/,'_'} || rand.to_s.h[0..3]
        loc = date[0..10].gsub(/[-T]/,'/') + name
      else
        puts ps,ps.size
      end

      uri = '//' + e['SERVER_NAME'] + '/forum/' + sub + '/' + loc

      post = {'uri' => uri, Date => date,
        Type => R[SIOCt+'BoardPost'],
        Content => CleanHTML[content]}

      post[Title] = title.hrefs if title && !title.empty?

      file = p['file'] # optional attachment
      if file && file[:type].match(/^image/)
        basename = file[:filename]
      end

      doc = uri.R.jsonDoc
      doc.w({uri=>post},true) # save

      [303,{'Location' => uri},[]]
    else
      [303,{'Location' => d.uri},[]]
    end

  }

  View[SIOCt+'BoardPost'] = -> d,e {
    d.resourcesOfType(SIOCt+'BoardPost').map{|post|
      t = post[Title] || '#'
      {class: :boardPost, style: 'float: left',
        c: [{_: :a, href: post.uri, c: {_: :h3, c: t}}, post[Content]
           ]}}}

  View['subforum'] = -> d,e {
    [H.css('/css/forum', true),View[LDP+'Resource'][d,e],
     d.resourcesOfType(SIOCt+'BoardPost').map{|post|
       {class: :post_info,
         c: [{_: :a, class: :title, href: post.uri, c: post[Title]},
             {class: :time, c: post[Date]},
            ]}
     },
     {_: :a, href: '?view=makepost', class: :makepost, c: 'create'}
#     View['makepost'][d,e]
    ]
  }

  View['makepost'] = -> d,e {
    ['post to ',{_: :b, c: e['forum'].hrefs},
     {_: :form, method: :POST, enctype: "multipart/form-data",
       c: [{_: :input, title: :title, name: :title, size: 32},'<br>',
           {_: :textarea, rows: 12, cols: 48, name: :content},'<br>',
           {_: :input, type: :file, name: :file},
           {_: :input, type: :submit, value: 'post '}]}]}

end
