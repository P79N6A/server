watch __FILE__
class R

  Posts = '.p'

  GET['/forum'] = -> r,e {
    s = r.path.tail.split '/'
    s.shift if s[0] == 'forum'
    if s.size == 1 # sub
      e.q['set'] = 'page'
      e.q['view'] ||= 'subforum'
      nil
    elsif s.size == 5 # thread
      e.q['set'] = SIOC+'Thread'
      r.descend.child(Posts).setEnv(e).response # paginated posts
    else
      nil
    end}

  FileSet[SIOC+'Thread'] = -> d,r,m {
    set = FileSet['page'][d,r,m] # current page of posts
    unless set.empty?
      set.unshift d.parentURI.jsonDoc # thread info
      m['#new'] = {Type => '#newpost'.R} # post skeleton
    end
    set}

  ViewGroup[FOAF+'Person'] = -> d,e {
    [{_: :style, c: "
.people {float: left; background-color: #eee; max-width: 18em}
.people > a {display: block; background-color:#fff; color: #00f; font-size: 1.25em; margin: .2em}
"}, {class: :people, c: d.map{|uri, person|{_: :a, href: uri, c: person[Name]}}}]}

  ViewGroup[FOAF+'Group'] = -> d,e {
    [{_: :style, c: "
.foaf {float: right; background-color: #111; color: #ccc}
.foaf > a {background-color:#000; color: #fff; font-size: 1.25em; margin: .2em}
"}, {class: :foaf, c: d.map{|id, group|[{_: :a, href: id, c: group.R.fragment}, group[Name], '<br>']}}]}

  POST['/forum'] = -> d,e{
    p = (Rack::Request.new d.env).params
    s = d.path.tail.split '/'
    prefix = '/' + s.shift if s[0] == 'forum'

    sub = '//' + e['SERVER_NAME'] + (prefix || '') + '/' + s[0]
  title = p['title'][0..127].hrefs
content = StripHTML[p['content']]
   date = Time.now.iso8601
   file = p['file']

    content = "" if content.size > 65535
    if s.size == 1 # subforum level - posting a new thread

      thread = sub + '/' + date[0..10].gsub(/[-T]/,'/') + (p['title'].empty? ? date : p['title']).gsub(/\W+/,'_')
      info = {
        'uri' => thread,
        Date => date,
        Type => R[SIOC+'Thread'],
        Title => title,
        SIOC+'has_container' => R[sub]}

      info.R.jsonDoc.do{|d| d.w({thread => info},true) unless d.e || (!file && title.empty?)}

    else
      thread = sub + '/' + s[1..4].join('/')
    end

    sig = content.h[0..8]
    posts = thread + '/' + Posts + '/'

    if R[posts+'*'+sig+'.e'].glob.empty? # dupe-check
      uri = posts + date.gsub(/\D/,'.') + sig
      post = {
        'uri' => uri,
        Date => date,
        Type => R[SIOCt+'BoardPost'],
        SIOC+'has_discussion' => R[thread],
        Content => content}
      post[Title] = title if title

      if file && file[:type].match(/^image/) # optional attachment
        f = file[:tempfile]
        attachment = R[thread+'/.i'].mk.child file[:filename]
        FileUtils.cp f, attachment.pathPOSIX
        f.unlink
        post[SIOC+'attachment'] = attachment
        puts "img <http:#{attachment}>"
      end

      post.R.jsonDoc.w({uri=>post},true) unless !file && content.empty?
    end

    [303,{'Location' => thread},[]]}

  View[SIOC+'Thread'] = -> d,e {
    [H.css('/css/forum'),
     d.values.map{|thread|
      thread[SIOC+'has_container'].do{|c|
        c = c[0].R
        {_: :a, class: :forum, c: c.basename, href: c.uri}}}]}

  View[SIOCt+'BoardPost'] = -> d,e {
    d.values.map{|post|
      thread = post[SIOC+'has_discussion'].do{|t|t[0].uri} || '#'
      {class: :post,
        c: [{_: :a, c: '&uarr;', href: post.uri},
            {_: :a, href: thread,
              c: [{_: :b, c: post[Title]||'#'},' ',
                  {_: :span, class: :date, c: post[Date]}]},'<br>',
            post[SIOC+'attachment'].do{|a|ShowImage[a[0].uri]},
            post[Content]]}}}

  View['subforum'] = -> d,e {
    [H.css('/css/forum', true),  # CSS
     View[HTTP+'Response'][d,e], # pagination
     {class: :subforum, 
       c: d.resourcesOfType(SIOC+'Thread').map{|thread|
         preview = {}
         thread.R.child(Posts).take(2,:asc).map{|p| p.fileToGraph preview}
         [View[SIOCt+'BoardPost'][preview, e],'<br clear=all><hr>']}},
     {_: :a, href: '?view=newpost', class: :makepost, c: 'create'}]}

  View['#newpost'] = -> d,e {
    {_: :form, method: :POST, enctype: "multipart/form-data",
      c: [{_: :input, title: :title, name: :title, size: 48},'<br>',
          {_: :textarea, rows: 8, cols: 48, name: :content},'<br>',
          {_: :input, type: :file, name: :file},
          {_: :input, type: :submit, value: 'post '}]}}
  View['newpost'] = View['#newpost']

end
