watch __FILE__
class R

  RecentPosts = {}

  GET['/ch'] = -> r,e {
    path = r.justPath.uri.sub(/^\/(board|ch|forum)\/*/,'/').tail
    if path.match(/^[^\/]*\/?$/)
      if path.empty? # chan/forum list
        e.q['view'] ||= 'title'
        r.descend.setEnv(e).response
      else # paged posts of (sub)forum
        r.q['c'] ||= 16
        r.q['set']  ||= 'page'
        r.q['view'] ||= 'threads'
        nil
      end
    elsif path.match /\/post$/# new
      e.q['view'] = 'board_post_form'
      e.htmlResponse({})
    else # post
      
    end}

  POST['/ch'] = -> d,e{
    p = (Rack::Request.new d.env).params # parse input
    content = p['content']
    if content && !content.empty?
      host = '//' + e['SERVER_NAME']
      path = Time.now.iso8601[0..18].gsub(/[-T]/,'/') + '.' + ( p['title'].do{|t|t.gsub /[?#\s\/]/,'_'} || rand.to_s.h[0..3] )
      uri = host + '/' + path

      post = { # post as Hash+JSON
        'uri' => uri,
        Type => R[SIOCt+'BoardPost'],
        Content => CleanHTML[content],
      }
      p['title'].do{|t| post[Title] = t.hrefs}

      # optional attachment
      file = p['file']
      if file && file[:type].match(/^image/)
        basename = file[:filename]
      end

      doc = R[uri].jsonDoc      # doc
      doc.w({uri => post},true) # save

      [303,{'Location' => uri},[]]
    else
      [303,{'Location' => d.uri},[]]
    end}

  View['board_post_form'] = -> d,e {
    {_: :form, method: :POST, enctype: "multipart/form-data",
      c: [{_: :input, title: :title, name: :title, size: 32},'<br>',
          {_: :textarea, rows: 8, cols: 32, name: :content},'<br>',
          {_: :input, type: :file, name: :file},
          {_: :input, type: :submit, value: 'post '}]}}

end
