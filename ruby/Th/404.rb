class E

  # 404 response URI
  E404 = 'req/'+HTTP+'404'

  # 404 response function
  fn E404,->e,r{
    u = e.uri     # response URI
    g = {u => {}} # response graph
    s = g[u]      # resource pointer
    # add request data to response graph
    r.map{|k,v| s[k] = [v] }
    s[Type] = [E[HTTP+'404']]
    s['uri'] = u
    s['QUERY'] = [r.q]
    s['ACCEPT']= [r.accept]
    s['SERVER_SOFTWARE']=[Version.E]
    s['http://buzzword.org.uk/rdf/personal-link-types#edit']=[E[u+'?view=edit&graph=_']]
    %w{CHARSET LANGUAGE ENCODING}.map{|a|s['ACCEPT_'+a] = [(r.accept_ '_' + a)]}
    # output
    r.q.delete 'view' # use 404 view if HTML
    [404,{'Content-Type'=> r.format},[e.render(r.format,g,r)]]}

  # qs y=404 to force a 404 response
  F['req/404'] = F[E404]

  fn 'view/'+HTTP+'404',->d,e{
    [H.css('/css/404'),{_: :h1, c: '404'},d.html]}

  # 404.css if fs content is missing
  fn '/css/404.css/GET',->e,r{
    [200,{'Content-Type'=>'text/css'},
["body {background-color:#000;color:#fff; font-family: sans-serif}
a {font-size:1.05em;background-color:#1ef;color:#000;text-decoration:none;padding:.1em}
td.key {text-align:right}
td.key .frag {font-weight:bold;background-color:#0f0;color:#000;padding-left:.2em;border-radius:.38em 0 0 .38em}
td.key .abbr {color:#eee;font-size:.92em}
td.val {border-style:dotted;border-width:0 0 .1em 0;border-color:#00f;}"]]}

  # show response-codes for a list of URIs
  def checkURIs
    r = uris.select{|u|u.to_s.match /^http/}.map{|u|
      c = [`curl -IsA 404? "#{u}"`.lines.to_a[0].match(/\d{3}/)[0].to_i,u] # HEAD
     #c = [`curl -s -o /dev/null -w %{http_code} "#{u}"`.chomp.to_i,u] # GET
      puts c.join ' ' 
      c # status, uri tuple
    }
    puts "\n\n"
    r.map{|c|
      # show anomalies
      puts c.join(' ') unless c[0] == 200
    }
  end

end
