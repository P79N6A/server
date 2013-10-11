
class Hash

  def graph g
    g.merge!({uri=>self})
  end

  def mergeGraph g
    g.values.each do |r|
      r.triples do |s,p,o|
        self[s] = {'uri' => s} unless self[s].class == Hash 
        self[s][p] ||= []
        self[s][p].push o unless self[s][p].member? o
      end
    end
    self
  end

  def attr p;map{|_,r|r[p].do{|o|return o}}; nil end

  # self -> tripleStream
  def triples
    s = uri
    map{|p,o|
      o.class == Array ? o.each{|o| yield s,p,o} : yield(s,p,o) unless p=='uri'}
  end

end

class E

  # fromStream :: Graph -> tripleStream -> Graph
  def fromStream m,*i
    send(*i) do |s,p,o|
      m[s] = {'uri' => s} unless m[s].class == Hash 
      m[s][p] ||= []
      m[s][p].push o unless m[s][p].member? o
    end; m
  end

  # tripleStream pipeline
  fn 'graph/|',->e,_,m{e.fromStream m, *_['|'].split(/,/)}

  def E.graphFromStream s
    fn 'graph/'+s.to_s,->e,_,m{e.fromStream m, s}    
  end

  # graph thunk
  fn 'graph/_',->d,_,m{ m[d.uri] = {} }

  # to_h :: -> Hash
  def to_h
    {'uri'=>uri}
  end

  def triplrMIMEdispatch &b;mime.do{|mime|
    yield uri,E::Type,(E MIMEtype+mime)
      (MIMEsource[mime]||
       MIMEsource[mime.split(/\//)[0]]).do{|s|
        send *s,&b }}
  end

  def graphFromFile g={}
    g.mergeGraph r(true) if ext=='e' # JSON -> graph
    [:triplrInode,        # filesystem data
     :triplrMIMEdispatch].# format-specific tripleStream
      each{|i| fromStream g,i } # tripleStream -> Graph
    g
  end

  def graph g={}
    docs.map{|d|d.graphFromFile g}  # tripleStream -> graph
    g
  end

  # render :: MIME, Graph, env -> String
  def render mime, d, e
   E[Render+mime].y d,e
  end

end
