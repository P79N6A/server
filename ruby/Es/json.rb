class Hash

  def graph g
    g.merge!({uri=>self})
  end

  def mergeGraph g
    g.triples{|s,p,o|
      self[s] = {'uri' => s} unless self[s].class == Hash 
      self[s][p] ||= []
      self[s][p].push o unless self[s][p].member? o } if g
    self
  end

  # self -> tripleStream
  def triples &f
    map{|s,r|
      r.map{|p,o|
        o.class == Array ? o.each{|o| yield s,p,o} : yield(s,p,o) unless p=='uri'}}
  end

end

class E

  def triplrJSON
    yield uri, '/application/json', (JSON.parse read) if e
  end

  def insertDocs triplr, h=nil, p=[], &b
    graph = fromStream({},triplr)
    graph.map{|u,r| # stream -> graph
      e = u.E           # resource
      j = e.ef          # doc
      j.e ||            # exists?
      (puts "in #{u}"
       j.w({u=>r},true) # insert
       p.map{|p|        # each indexable property
     r[p].do{|v|        # values exists?
       v.map{|o|        # each value
        e.index p,o}}}  # property index 
       e.roonga h if h  # full-text index
       # opaqueURI path <> sibling of docBase path
       u = e.a '.e'
       (j.ln u) unless ((j.uri == u.uri) || u.e))}
    # pass through triples if requested
    graph.triples &b if b
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
