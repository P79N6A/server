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
      r.descend.child('.p').setEnv(e).response # paginated posts
    else
      nil
    end}

  POST['/forum'] = -> d,e{
    p = (Rack::Request.new d.env).params
    pathSegs = d.path.sub(/^\/forum/,'').tail.split '/'

    sub = '//' + e['SERVER_NAME'] + '/forum/' + pathSegs[0]
  title = p['title'].do{|t| !t.empty? && t.hrefs}
content = CleanHTML[p['content']]
   date = Time.now.iso8601

    if sub && content && !content.empty?

      if pathSegs.size == 1 # post thread to subforum container

        thread = sub + '/' + date[0..10].gsub(/[-T]/,'/') + (p['title'].do{|t|t.gsub /[?#\s\.\/]+/,'_'} || rand.to_s.h[0..3])
        info = {
          'uri' => thread,
          Date => date,
          Type => R[SIOC+'Thread'],
          Title => title||'untitled',
          SIOC+'has_container' => R[sub]}

        info.R.jsonDoc.do{|d| d.w({thread => info},true) unless d.e}

      else # thread container
        thread = sub + '/' + pathSegs[1..4].join('/')
      end

      sig = content.h[0..8]
      posts = thread + '/.p/'

      if !R[posts+'*'+sig+'.e'].glob.empty? # duplicate
#        puts "duplicate post"
      else
        uri = posts + date.gsub(/\D/,'.') + sig
        post = {
          'uri' => uri,
          Date => date,
          Type => R[SIOCt+'BoardPost'],
          SIOC+'has_container' => R[thread],
          Content => content}
        post[Title] = title if title

        file = p['file'] # optional attachment
        if file && file[:type].match(/^image/)
          basename = file[:filename]
        end

        post.R.jsonDoc.w({uri=>post},true)
      end

      [303,{'Location' => thread},[]]
    else # content empty, skip
      [303,{'Location' => d.uri},[]]
    end}
=begin
  View[SIOCt+'BoardPost'] = -> d,e {
    d.resourcesOfType(SIOCt+'BoardPost').map{|post|
      t = post[Title] || '#'
      {class: :boardPost, style: 'float: left',
        c: [{_: :a, href: post.uri, c: {_: :h3, c: t}}, post[Content]
           ]}}}
=end
  View['subforum'] = -> d,e {
    [H.css('/css/forum', true),View[LDP+'Resource'][d,e],
     d.resourcesOfType(SIOC+'Thread').map{|post|
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
