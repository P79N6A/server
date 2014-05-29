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
    elsif n = path.match(/^[^\/]+\/\d{4}\/\d\d\/\d\d\/([^\/]+)\/?$/) # thread
      e.q['set'] = 'page'
      e.q['view'] ||= 'timegraph'
      r.descend.child('.p').setEnv(e).response # paginated osts
    else
      nil
    end}

  POST['/forum'] = -> d,e{
    p = (Rack::Request.new d.env).params
    pathSegs = d.path.sub(/^\/forum/,'').tail.split '/'

    sub = '//' + e['SERVER_NAME'] + '/forum/' + pathSegs[0] + '/'
  title = p['title']
content = p['content']
   date = Time.now.iso8601

    post = {
      Date => date,
      Type => R[SIOC+'Thread'],
      Title => title && !title.empty? && title.hrefs || 'untitled',
    }

    if sub && content && !content.empty?

      if pathSegs.size == 1 # new thread

        uri = sub + date[0..10].gsub(/[-T]/,'/') + (p['title'].do{|t|t.gsub /[?#\s\.\/]+/,'_'} || rand.to_s.h[0..3])
        thread = post['uri'] = uri # minted URI of date + title

        uri.R.jsonDoc.w({uri=>post},true) # store thread info

      else
        thread = sub + pathSegs[1..4].join('/')
      end

      uri = thread + '/.p/' + date.gsub(/\D/,'.')
      post['uri'] = uri
      post[Type] = R[SIOCt+'BoardPost']
      post[SIOC+'has_container'] = R[thread]
      post[Content] = CleanHTML[content]

      file = p['file'] # optional attachment
      if file && file[:type].match(/^image/)
        basename = file[:filename]
      end

      uri.R.jsonDoc.w({uri=>post},true) # store post

      [303,{'Location' => thread},[]]
    else # noop
      [303,{'Location' => d.uri},[]]
    end}

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
