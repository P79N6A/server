class R

  GET['/500'] = -> e,r {
    r[:Response]['ETag'] = Errors.keys.sort.h
    e.condResponse ->{Render['text/html'][Errors, r]}}

  E500 = -> x,e {
    uri = e['SERVER_NAME']+e['REQUEST_URI']
    out = [500, uri, x.class, x.message, x.backtrace].flatten.map(&:to_s)
    Errors[uri] ||= {'uri' => '//'+uri, Content => '<pre>'+out.join("\n").noHTML+'</pre>'}
    $stderr.puts out[0..3].join(' '), out[4..-1]

    [500,{'Content-Type'=>'text/html'},
     [H[{_: :html,
          c: [{_: :head,
                c: [{_: :title, c: 500},(H.css '/css/500')]},
              {_: :body,
                c: [{_: :h1, c: 500},
                    {_: :table,
                      c: [{_: :tr, c: [{_: :td, c: {_: :b, c: x.class}},
                                       {_: :td, class: :message, colspan: 2, c: x.message.noHTML}]},
                          x.backtrace.map{|f| p = f.split /:/, 3
                            {_: :tr, c: [{_: :td, class: :path, c: p[0].R.abbr},
                                         {_: :td, class: :index, c: p[1]},
                                         {_: :td, class: :context, c: (p[2]||'').noHTML }]}}]}]}]}]]]}

  def R.log e, s, h, b
    ua = e['HTTP_USER_AGENT'] || ''
    u = '#' + ua.slugify
    Stats[:agent] ||= {}
    Stats[:agent][u] ||= {Title => ua.hrefs}
    Stats[:agent][u][:count] ||= 0
    Stats[:agent][u][:count] += 1

    Stats[:status] ||= {}
    Stats[:status][s] ||= 0
    Stats[:status][s] += 1

    host = e['SERVER_NAME']
    Stats[:host] ||= {}
    Stats[:host][host] ||= 0
    Stats[:host][host] += 1

    mime = h['Content-Type'].do{|t|t.split(';')[0]}
    Stats[:format] ||= {}
    Stats[:format][mime] ||= 0
    Stats[:format][mime] += 1

    puts [ e['REQUEST_METHOD'], s, '<'+e.uri+'>', ua, '<'+e.user+'>', e['HTTP_REFERER']
         ].join ' '

  end

  GET['/stat'] = -> e,r {
    b = {_: :table,
      c: [{_: :tr, class: :head, c: {_: :td, colspan: 2, c: :status}},
          Stats[:status].sort_by{|_,c|-c}.map{|status, count|
            {_: :tr, c: [{_: :td, c: status},
                         {_: :td, class: :count, c: count}]}},

          {_: :tr, class: :head, c: {_: :td, colspan: 2, c: :domain}},
          Stats[:host].sort_by{|_,c|-c}.map{|host, count|
            {_: :tr, c: [{_: :td, class: :count, c: count},
                         {_: :td, c: {_: :a, href: '//'+host, c: host}}]}},

          {_: :tr, class: :head, c: {_: :td, colspan: 2, c: :MIME}},
          Stats[:format].sort_by{|_,c|-c}.map{|mime, count|
            {_: :tr, c: [{_: :td, class: :count, c: count},
                         {_: :td, c: mime}]}},

          {_: :tr, class: :head, c: {_: :td, colspan: 2, c: :agent}},
          Stats[:agent].values.sort_by{|a|-a[:count]}[0..48].map{|a|
            {_: :tr, c: [{_: :td, class: :count, c: a[:count]},
                         {_: :td, c: a[Title]}]}},

          {_: :style, c: "
a {text-decoration: none; font-size: 1.1em}
.count {font-weight: bold}
tr.head > td {font-weight: bold; font-size: 1.6em; padding-top: .3em}"}]}

    [200, {'Content-Type'=>'text/html'}, [H(b)]]}

end
