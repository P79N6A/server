class Hash

  def graph g
    g.merge!({uri=>self})
  end

  def mergeGraph g
    g.values.each{|r|
      r.triples{|s,p,o|
        self[s] = {'uri' => s} unless self[s].class == Hash 
        self[s][p] ||= []
        self[s][p].push o unless self[s][p].member? o }} if g
    self
  end

  # tripleStream emitter
  def triples
    s = uri
    map{|p,o|
      o.class == Array ? o.each{|o| yield s,p,o} : yield(s,p,o) unless p=='uri'}
  end

end

class E

  def triplrJSON
    yield uri, '/application/json', (JSON.parse read) if e
  end


  # tripleStream -> fs
  def addJSON i,g,p=[]
    fromStream({},i).map{|u,r| # stream -> graph
      (E u).do{|e| # resource
        j = e.ef   # inode
        j.e ||     # exists?
        (p.map{|p|r[p].do{|o|e.index p,o[0]}} # index properties
         j.w({u => r},true) # write doc
         puts "a #{e}"
         # link opaque-URI docs as siblings of base-URI for doc-discoverability
         e.a('.e').do{|u| (j.ln u) unless ((j.uri == u.uri) || u.e)  }
         e.roonga g # index content
         )}}
    self
  rescue Exception => e
    puts "addJSON #{e}"
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
