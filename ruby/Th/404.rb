#watch __FILE__
class E

  E404 = 'req/'+HTTP+'404'

  fn E404,->e,r{
   id = e.uri     # response URI
    g = {id=>{}}  # response graph
    s = g[id]     # resource pointer

    # link request-environment fields
    r.map{|k,v| 
      s[k.sub(/^HTTP_/,W3+'2011/http-headers#').gsub('_','-').downcase] = k == 'uri' ? v : [v] }
    s[Type] = [E[HTTP+'404']]
    s['/qs'] = [r.q]
    s['ACCEPT']= [r.accept]
    %w{CHARSET LANGUAGE ENCODING}.map{|a|s['ACCEPT_'+a] = [(r.accept_ '_' + a)]}

    # link to editable resource
    s[Edit]=[E[r['REQUEST_PATH']+'?view=edit&graph=editable&nocache']]
    # output

    [404,{'Content-Type'=> r.format},[e.render(r.format,g,r)]]}
  
  fn 'view/'+HTTP+'404',->d,e{
    [H.css('/css/404'),d.html]}

end
