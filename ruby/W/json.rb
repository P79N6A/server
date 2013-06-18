class E

  def triplrJSON
    yield uri, '/application/json', (JSON.parse read) if e
  end


  # addJSON :: tripleStream -> JSON graph (fs)
  def addJSON i,g,p=[]
    fromStream({},i).map{|u,r| # stream -> graph
      (E u).do{|e| # resource
        j = e.docBase.a '.e'
        j.e || # exists?
        (p.map{|p|r[p].do{|o|e.index p,o[0]}} # index properties
         j.w({u => r},true) # write doc
         puts "a #{e}"
         # opaque URI docs locatable directly or as siblings of hashed base/graph URI
         e.a('.e').do{|u|j.ln u unless j.uri == u.uri }
         e.roonga g # index content
         )}}
    self
  end

  fn 'view/application/json',->m,e{
    m.map{|u,j|
      e.q['sel'].do{|s|
        c = j['/application/json'][0]
        s.split(/\./).map{|s|
          s = s.to_i if s.match(/^\d$/)
          c = c[s] }
        [{_: :a,
           href: u+'?q=json&view=application/json&sel='+s,
           c: {_: :b, c: u+'#'+s}}, c.html]
      }||[{_: :h3, c: u},j.html]}}
  
  def to_json *a
    to_h.to_json *a
  end

  fn Render+'application/json',->d,_=nil{[d].to_json}

end
