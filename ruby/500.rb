class R

  GET['/500'] = -> e,r {
    r[:Response]['ETag'] = Errors.keys.sort.h
    e.condResponse ->{Render['text/html'][Errors, r]}}

  GET['/stat'] = -> e,r {
    r[:Response]['ETag'] = rand.to_s.h
    e.condResponse ->{Render['text/html'][Stats, r]}}

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

end
