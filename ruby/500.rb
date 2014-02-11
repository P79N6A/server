#watch __FILE__
class R
  
  Errors ||= {}

  fn 'E500',->x,e{
    stack = x.backtrace
    $stderr.puts [500, e['REQUEST_URI'], x.class, x.message, stack[0]].join ' '

    Errors[e['uri']] ||= {}
    Errors[e['uri']][:time] = Time.now
    Errors[e['uri']][:env] = [e, x.class.to_s, x.message, stack.join('<br>')]

    [500,{'Content-Type'=>'text/html'},
     [H[{_: :html,
          c: [{_: :head,
                c: [{_: :title, c: 500},(H.css '/css/500')]},
              {_: :body,
                c: [{_: :h1, c: 500},
                    {_: :table,
                      c: [{_: :tr,c: [{_: :td, c: {_: :b, c: x.class}},{_: :td, class: :space},{_: :td, class: :message, c: x.message.hrefs}]},
                          stack.map{|f| p = f.split /:/, 3
                            {_: :tr,
                              c: [{_: :td, class: :path, c: p[0].abbrURI},
                                  {_: :td, class: :index, c: p[1]},
                                  {_: :td, class: :context, c: (p[2]||'').hrefs}].cr}}.cr]}]}]}]]]}

  F['/500/GET'] = ->e,r{
    body = H [Errors.sort_by{|u,r|r[:time]}.reverse.html, H.css('/css/500')]
    [200, {'Content-Type'=>'text/html; charset=utf-8'}, [body]]}

  F['view/'+COGS+'Exception']=->e,r{
    e.values.map{|e|
      {style: 'border-radius:1em;background-color:#333;color:#eee;float:left;max-width:42em',
        c: [{_: :h2, c: "<b style='background-color:#f00'>&#0191;</b>"+(e[Title]||[]).to_s},
            e[Content]||''
           ]}}}

  # filesystem takes priority over this if it's found
  fn '/css/500.css/GET',->e,r{
    [200,{'Content-Type'=>'text/css'},["
body {margin:0; font-family: sans-serif; background-color:#fff; color:#000}
h1 {padding:.2em; background-color:#f00; color:#fff; margin:0}
div {display:inline}
table {border-spacing:0;margin:0}
b {background-color:#eee;color:#500;padding:.1em .3em .1em .3em}
.frag {font-weight:bold; color:#000; background-color:#{R.cs}}
td.space {background-color:#ddd}
td.message {background-color:#009;color:#fff}
td.path {text-align:right}
td.index {text-align:right;border-color:#000;border-width:0 0 .1em 0;border-style:dotted;background-color:#ddd;color:#000}
td.context {border-color:#ddd;border-width:0 0 .1em 0;border-style:dotted;padding:.15em}"]]}

end
