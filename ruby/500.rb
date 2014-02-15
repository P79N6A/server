class R

  fn 'E500',->x,e{
    $stderr.puts [500, e['REQUEST_URI'], x.class, x.message].join ' '
    [500,{'Content-Type'=>'text/html'},
     [H[{_: :html,
          c: [{_: :head,c: [{_: :title, c: 500},(H.css '/css/500')]},
              {_: :body,
                c: [{_: :h1, c: 500},
                    {_: :table,
                      c: [{_: :tr,c: [{_: :td, c: {_: :b, c: x.class}},{_: :td, class: :space},{_: :td, class: :message, c: x.message.hrefs}]},
                          x.backtrace.map{|f| p = f.split /:/, 3
                            {_: :tr,
                              c: [{_: :td, class: :path, c: p[0].abbrURI},
                                  {_: :td, class: :index, c: p[1]},
                                  {_: :td, class: :context, c: (p[2]||'').hrefs}].cr}}.cr]}]}]}]]]}

  F['view/'+COGS+'Exception']=->e,r{
    e.values.map{|e|
      {style: 'border-radius:1em;background-color:#333;color:#eee;float:left;max-width:42em',
        c: [{_: :h2, c: "<b style='background-color:#f00'>&#0191;</b>"+(e[Title]||[]).to_s},
            e[Content]||'']}}}

end

