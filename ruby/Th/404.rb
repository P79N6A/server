class E

  E404 = 'req/'+HTTP+'404'

  fn E404,->e,r{
    u = e.uri     # response URI
    g = {u => {}} # response graph
    s = g[u]      # resource pointer

    # request environment vars to response graph
    r.map{|k,v| s[k] = [v] }
    s[Type] = [E[HTTP+'404']]
    s['uri'] = u
    s['QUERY'] = [r.q]
    s['ACCEPT']= [r.accept]
    %w{CHARSET LANGUAGE ENCODING}.map{|a|s['ACCEPT_'+a] = [(r.accept_ '_' + a)]}

    # link to editable resource
    s[Edit]=[E[r['REQUEST_PATH']+'?view=edit&graph=editable&nocache']]
    r.q.delete 'view'

    # output
    [404,{'Content-Type'=> r.format},[e.render(r.format,g,r)]]}

  fn 'view/'+HTTP+'404',->d,e{
    [H.css('/css/404'),{_: :h1, c: '404'},d.html]}

  # 404.css fallback
  fn '/css/404.css/GET',->e,r{
    [200,{'Content-Type'=>'text/css'},
["body {background-color:#000;color:#fff; font-family: sans-serif}
a {font-size:1.05em;background-color:#1ef;color:#000;text-decoration:none;padding:.1em}
td.key {text-align:right}
td.key .frag {font-weight:bold;background-color:#0f0;color:#000;padding-left:.2em;border-radius:.38em 0 0 .38em}
td.key .abbr {color:#eee;font-size:.92em}
td.val {border-style:dotted;border-width:0 0 .1em 0;border-color:#00f;}"]]}

end
