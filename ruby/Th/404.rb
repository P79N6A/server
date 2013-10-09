#watch __FILE__
class E

  E404 = 'req/'+HTTP+'404'

  fn E404,->e,r{
   id = e.uri     # response URI
    g = {id=>{}}  # response graph
    s = g[id]     # resource pointer

    # link request-environment fields
    r.map{|k,v| 
      s[k.sub(/^HTTP_/,Header).gsub('_','-').downcase] = k == 'uri' ? v : [v] }
    s[Type] = [E[HTTP+'404']]
    s['/qs'] = [r.q]
    s['ACCEPT']= [r.accept]
    s['request-method'] = [H[{_: :a, c: s['request-method'][0], style: 'font-weight: bold',
                               href: 'http://www.w3.org/Protocols/HTTP/Methods/'+s['request-method'][0]+'.html'}]]
    s['server-protocol'] = [E['http://www.w3.org/Protocols/rfc2616/rfc2616.html']]
    s['server-software'] = [H[{_: :a, href: 'http://github.com/infodaemon/www', c: :infodaemon}]]
    ['remote-addr','server-name',Header+'host'].map{|a|s[a] = [E['http://' + s[a][0]]] }
    %w{CHARSET LANGUAGE ENCODING}.map{|a|s['ACCEPT_'+a] = [(r.accept_ '_' + a)]}

    # link to editable resource
    s[Edit]=[E[r['REQUEST_PATH']+'?view=edit&graph=editable&nocache']]
    # output
    r.q.delete 'view'
    [404,{'Content-Type'=> r.format},[e.render(r.format,g,r)]]}
  
  fn 'view/'+HTTP+'404',->d,e{
    [H.css('/css/404'),d.html]}

end
