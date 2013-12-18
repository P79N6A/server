class E
  
  Errors ||= {}

  fn 'E500',->x,e{
    msg = x.message
  stack = x.backtrace
    $stderr.puts [500, e['REQUEST_URI'], msg, stack[0]].join ' '

    Errors[e['uri']] ||= {}
    Errors[e['uri']][:time] = Time.now
    Errors[e['uri']][:what] = [msg,stack[0]]

    [500,{'Content-Type'=>'text/html'},
     [H[{_: :html,
          c: [{_: :head,
                c: [{_: :title, c: 500},(H.css '/css/500')]},
              {_: :body,
                c: [{_: :h1, c: 500},
                    {_: :table,
                      c: [{_: :tr,c: [{_: :td, c: {_: :b, c: x.class}},{_: :td, class: :space},{_: :td, class: :message, c: msg.hrefs}]},
                          stack.map{|f| p = f.split /:/, 3
                            {_: :tr,
                              c: [{_: :td, class: :path, c: p[0].abbrURI},
                                  {_: :td, class: :index, c: p[1]},
                                  {_: :td, class: :context, c: (p[2]||'').hrefs}].cr}}.cr]}]}]}]]]}

  F['/500/GET'] = ->e,r{H([Errors.sort_by{|u,r|r[:time]}.reverse.html,H.css('/css/500')]).hR}
  F['/500/test/GET'] = ->e,r{1/0}

  # filesystem /css/500.css takes priority over this if it's found
  fn '/css/500.css/GET',->e,r{
    [200,{'Content-Type'=>'text/css'},["
body {margin:0; font-family: sans-serif; background-color:#fff; color:#000}
h1 {padding:.2em; background-color:#f00; color:#fff; margin:0}
div {display:inline}
table {border-spacing:0;margin:0}
b {background-color:#eee;color:#500;padding:.1em .3em .1em .3em}
.frag {font-weight:bold; color:#000; background-color:#{E.cs}}
td.space {background-color:#ddd}
td.message {background-color:#009;color:#fff}
td.path {text-align:right}
td.index {text-align:right;border-color:#000;border-width:0 0 .1em 0;border-style:dotted;background-color:#ddd;color:#000}
td.context {border-color:#ddd;border-width:0 0 .1em 0;border-style:dotted;padding:.15em}"]]}

end
