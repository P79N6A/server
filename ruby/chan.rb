watch __FILE__
class R

  GET['/ch'] = -> r,e {
    path = r.justPath.uri.sub(/^\/ch\/*/,'/').tail
    if path.match(/^[^\/]*\/?$/) # root or child thereof
      if path.empty? # sub index
        e.q['view'] ||= 'title'
        r.descend.setEnv(e).response
      else # sub
        r.q['set'] = 'ch'
        e['sub'] = path
        nil
      end
    elsif p = path.match(/([^\/]+)\/post$/) # create
      e.q['view'] = 'newBoardPost'
      e['sub'] = p[1]
      e.htmlResponse({})
    else # post
      
    end}

  FileSet['ch'] = ->d,e,m{
    m['#new'] = {Type => R['newBoardPost']}
    e['c'] ||= 32
    FileSet['page'][d,e,m]
  }

  POST['/ch'] = -> d,e{
    path = d.justPath.uri.sub(/^\/ch\/*/,'/').tail
    sub = path.match(/[^\/]+/)[0]
    p = (Rack::Request.new d.env).params
    content = p['content']

    if content && !content.empty?

      name = p['title'].do{|t|t.gsub /[?#\s\.\/]+/,'_'} || rand.to_s.h[0..3]

      uri = '//' + e['SERVER_NAME'] + '/' + sub + '/' + Time.now.iso8601[0..7].gsub(/-/,'/') + name

      post = {'uri' => uri,
        Type => R[SIOCt+'BoardPost'],
        Title => (p['title']||'').hrefs,
        Content => CleanHTML[content]}

      file = p['file'] # optional attachment
      if file && file[:type].match(/^image/)
        basename = file[:filename]
      end

      doc = uri.R.jsonDoc
      doc.w({uri=>post},true) # save
      doc.ln_s R['//' + e['SERVER_NAME'] + '/ch/' + sub + '/' + Time.now.iso8601[0..18].gsub(/[-T]/,'/') + '.' + name]

      [303,{'Location' => uri},[]]
    else
      [303,{'Location' => d.uri},[]]
    end}

  View[SIOCt+'BoardPost'] = -> d,e {
    d.resourcesOfType(SIOCt+'BoardPost').map{|post|
      {class: :boardPost, style: 'float: left',
        c: [post[Title].do{|t|{_: :a, href: post.uri, c: {_: :h3, c: t}}},
            post[Content]
           ]}}}

  View['newBoardPost'] = -> d,e {
    ['post on ',{_: :b, c: e['sub'].hrefs},
     {_: :form, method: :POST, enctype: "multipart/form-data",
       c: [{_: :input, title: :title, name: :title, size: 32},'<br>',
           {_: :textarea, rows: 8, cols: 32, name: :content},'<br>',
           {_: :input, type: :file, name: :file},
           {_: :input, type: :submit, value: 'post '}]}]}

end
