watch __FILE__
class R

  RecentPosts = {}

  GET['/ch'] = -> r,e {
    path = r.justPath.uri.sub(/^\/(board|ch|forum)\/*/,'/').tail
    if path.match(/^[^\/]*\/?$/) # root-level or child
      if path.empty? # list subs
        e.q['view'] ||= 'title'
        r.descend.setEnv(e).response
      else # sub
        r.q['set'] = 'ch'
        e['sub'] = path
        nil
      end
    elsif p = path.match(/([^\/]+)\/post$/) # new
      e.q['view'] = 'boardPost-form'
      e['sub'] = p[1]
      e.htmlResponse({})
    else # post
      
    end}

  FileSet['ch'] = ->d,e,m{
    m['#new'] = {Type => R['newBoardPost']}
    FileSet['page'][d,e,m]}

  POST['/ch'] = -> d,e{
    p = (Rack::Request.new d.env).params # parse input
    content = p['content']
    if content && !content.empty?
      uri = '//' + e['SERVER_NAME'] + '/' +
        Time.now.iso8601[0..18].gsub(/[-T]/,'/') + '.' +
        ( p['title'].do{|t|t.gsub /[?#\s\/]/,'_'} || rand.to_s.h[0..3] )

      post = {'uri' => uri,
        Type => R[SIOCt+'BoardPost'],
        Content => CleanHTML[content]}

      p['title'].do{|t| post[Title] = t.hrefs}

      # optional attachment
      file = p['file']
      if file && file[:type].match(/^image/)
        basename = file[:filename]
      end

      R[uri].jsonDoc.w({uri=>post},true) # save

      [303,{'Location' => uri},[]]
    else
      [303,{'Location' => d.uri},[]]
    end}

  View['newBoardPost'] = -> d,e {
    ['post on ',{_: :b, c: e['sub'].hrefs},
     {_: :form, method: :POST, enctype: "multipart/form-data",
       c: [{_: :input, title: :title, name: :title, size: 32},'<br>',
           {_: :textarea, rows: 8, cols: 32, name: :content},'<br>',
           {_: :input, type: :file, name: :file},
           {_: :input, type: :submit, value: 'post '}]}]}

end
