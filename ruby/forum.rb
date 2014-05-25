watch __FILE__
class R

  GET['/forum'] = -> r,e {
    path = r.justPath.uri.sub(/^\/forum\/*/,'/').tail
    if path.match(/^[^\/]*\/?$/) # root or child thereof
      if path.empty? # sub index
        e.q['view'] ||= 'table'
        r.descend.setEnv(e).response
      else # sub
        r.q['set'] = 'forum'
        e['name'] = path
        nil
      end
    elsif p = path.match(/([^\/]+)\/post$/) # create
      e.q['view'] = 'newBoardPost'
      e['sub'] = p[1]
      e.htmlResponse({})
    else # post
      
    end}

  FileSet['forum'] = ->d,e,m{
    m['#new'] = {Type => R['newBoardPost']} # quick-post to this sub
    e['c'] ||= 12
    FileSet['page'][d,e,m] # merge with recently-bumped threads (fs sort is created order), ie recent-symlinks dir or RAM references
  }

  POST['/forum'] = -> d,e{
    ps = d.path.sub(/^\/forum/,'').tail.split '/'
    sub = ps[0]
    puts ps,ps.size
    p = (Rack::Request.new d.env).params
    title = p['title']
    content = p['content']
    if sub && content && !content.empty?

      if ps.size == 1 # new thread
        name = p['title'].do{|t|t.gsub /[?#\s\.\/]+/,'_'} || rand.to_s.h[0..3]
        loc = Time.now.iso8601[0..10].gsub(/[-T]/,'/') + name
      else
        
      end

      uri = '//' + e['SERVER_NAME'] + '/forum/' + sub + '/' + loc

      post = {'uri' => uri,
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
      puts "titlr",t
      {class: :boardPost, style: 'float: left',
        c: [{_: :a, href: post.uri, c: {_: :h3, c: t}}, post[Content]
           ]}}}

  View['newBoardPost'] = -> d,e {
    ['post on ',{_: :b, c: e['name'].hrefs},
     {_: :form, method: :POST, enctype: "multipart/form-data",
       c: [{_: :input, title: :title, name: :title, size: 32},'<br>',
           {_: :textarea, rows: 12, cols: 48, name: :content},'<br>',
           {_: :input, type: :file, name: :file},
           {_: :input, type: :submit, value: 'post '}]}]}

end
