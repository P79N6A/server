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
        nil
      end
    elsif n = path.match(/^[^\/]+\/\d{4}\/\d\d\/\d\d\/([^\/]+)\/?$/) # thread
      e.q['set'] = SIOC+'Thread'
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

      if R[posts+'*'+sig+'.e'].glob.empty? # non-duplicate
        uri = posts + date.gsub(/\D/,'.') + sig
        post = {
          'uri' => uri,
          Date => date,
          Type => R[SIOCt+'BoardPost'],
          SIOC+'has_discussion' => R[thread],
          Content => content}
        post[Title] = title if title

        file = p['file'] # optional attachment
        if file && file[:type].match(/^image/)
          f = file[:tempfile]
          FileUtils.cp f, posts.R.child(file[:filename]).pathPOSIX
          f.unlink
        end

        post.R.jsonDoc.w({uri=>post},true)
      end

      [303,{'Location' => thread},[]]
    else # content empty, skip
      [303,{'Location' => d.uri},[]]
    end}

  FileSet[SIOC+'Thread'] = -> d,r,m {
    set = FileSet['page'][d,r,m] # page of posts in thread
    unless set.empty?
      set.unshift d.parent.jsonDoc # thread container
      m['#post'] = {Type => 'newpost'.R} # blank post
    end
    set}


  View[SIOC+'Thread'] = -> d,e {
    [H.css('/css/forum'),
     d.values.map{|thread|
      thread[SIOC+'has_container'].do{|c|
        c = c[0].R
        {_: :a, c: c.basename, href: c.uri, style: 'border: .1em dotted #888;text-decoration: none'}}}]}

  View[SIOCt+'BoardPost'] = -> d,e {
    d.values.map{|post|
      {class: :post,
        c: [post[SIOC+'has_discussion'].do{|t|{_: :a, c: '&uarr;', href: t[0].uri}},
            {_: :a, href: post.uri,
              c: [{_: :b, c: post[Title]||'#'},' ',
                  {_: :span, class: :date, c: post[Date]}]},'<br>',
            post[Content]]}}}

  View['subforum'] = -> d,e {
    [H.css('/css/forum', true),View[LDP+'Resource'][d,e],
     d.resourcesOfType(SIOC+'Thread').map{|post|
       {class: :post_info,
         c: [{_: :a, class: :title, href: post.uri, c: post[Title]},
             {class: :time, c: post[Date]}]}},
     {_: :a, href: '?view=newpost', class: :makepost, c: 'create'}]}

  View['newpost'] = -> d,e {
    {_: :form, method: :POST, enctype: "multipart/form-data",
      c: [{_: :input, title: :title, name: :title, size: 48},'<br>',
          {_: :textarea, rows: 8, cols: 48, name: :content},'<br>',
          {_: :input, type: :file, name: :file},
          {_: :input, type: :submit, value: 'post '}]}}

end
