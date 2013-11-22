watch __FILE__
class E

  E404 = 'req/'+HTTP+'404'

  fn E404,->e,r{
   id = e.uri     # response URI
    g = {id=>{}}  # response graph
    s = g[id]     # resource pointer

    # link request-environment data
    fn = r['REQUEST_METHOD']
    r.map{|k,v| 
      s[Header + k] = k == 'uri' ? v : [v] }
    s[Type] = [E[HTTP+'Response']]
    s[HTTP+'statusCodeValue']=[404]
    s['#query'] = [r.q]
    s[Header+'ACCEPT'] = [r.accept]
    %w{CHARSET LANGUAGE ENCODING}.map{|a|
      s[Header+'ACCEPT_'+a] = [(r.accept_ '_' + a)]}
    s[HTTP+'MTHD'] = [H[{_: :a, c: fn, style: 'font-weight: bold', href: 'http://www.w3.org/Protocols/HTTP/Methods/'+fn+'.html'}]]
    s[Header+'HTTP_HOST'] = [E['http://' + s[Header+'HTTP_HOST'][0]]]

    # link to editable resource
    s[Edit]=[E[r['REQUEST_PATH']+'?view=edit&graph=editable']]

    # link to nearby resources
    s['#seeAlso']=[e.parent,*e.a('*').glob]

    r.q['view'] = '404'
    [404,{'Content-Type'=> r.format},[e.render(r.format,g,r)]]}
  
  fn 'view/404',->d,e{
    [H.css('/css/404'),{_: :style, c: "a {background-color:#{E.cs}}"},
     d.html]}

  # a small non-empty graph
  fn 'protograph/_',->d,_,m{
    m[d.uri] = {}
    rand.to_s.h}

  # check response-codes for a list of URIs (linebreak-separated *.u files)
  def checkURIs
    r = uris.select{|u|u.to_s.match /^http/}.map{|u|
      c = [`curl -IsA 404? "#{u}"`.lines.to_a[0].match(/\d{3}/)[0].to_i,u] # HEAD
      puts c.join ' ' 
      c } # status, uri tuple
    puts "\n\n"
    r.map{|c|
      # show anomalies
      puts c.join(' ') unless c[0] == 200 }
  end

end
