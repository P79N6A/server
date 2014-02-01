class E

  E404 = 'req/'+HTTP+'404'

  fn E404,->e,r{
   id = e.uri     # response URI
    g = {id=>{}}  # response graph
    s = g[id]     # resource pointer
   fn = r['REQUEST_METHOD']

    # request environment -> graph
r.map{|k,v| s[Header + k] = k == 'uri' ? v : [v] }
  %w{CHARSET LANGUAGE ENCODING}.map{|a|
    s[Header+'ACCEPT_'+a] = [r.accept_('_' + a)]}
       s[Header+'ACCEPT'] = [r.accept]
                  s[Type] = [E[HTTP+'Response']]
s[HTTP+'statusCodeValue'] = [404]
    s[Header+'HTTP_HOST'] = [E['http://' + s[Header+'HTTP_HOST'][0]]] if s[Header+'HTTP_HOST']
                  s[Edit] = [E[r['REQUEST_PATH']+'?graph=create']]
              s['#query'] = [r.q]
            s['#seeAlso'] = [e.parent,*e.a('*').glob]
              r.q['view'] = '404'

    [404,{'Content-Type'=> r.format},[e.render(r.format,g,r)]]}

  F['/E/GET'] = F[E404]  

  fn 'view/404',->d,e{
    [H.css('/css/404'),{_: :style, c: "a {background-color:#{E.cs}}"},
     d.html]}

  # a resource-placeholder graph
  fn 'protograph/blank',->d,_,m{
    m[d.uri] = {}
    rand.to_s.h}

  def checkURIs
    r = uris.map{|u|
      c = [`curl -IsA 404? "#{u}"`.lines.to_a[0].match(/\d{3}/)[0].to_i,u] # HEAD
      puts c.join ' ' 
      c } # status, uri tuple
    puts "\n\n"
    r.map{|c|
      # show anomalies
      puts c.join(' ') unless c[0] == 200 }
  end

end
