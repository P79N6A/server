#watch __FILE__
class E

  # Graph -> tripleStream -> Graph
  def fromStream m,*i
    send(*i) do |s,p,o|
      m[s] = {'uri' => s} unless m[s].class == Hash 
      m[s][p] ||= []
      m[s][p].push o unless m[s][p].member? o
    end; m
  end

  fn 'protograph/',->e,q,g{
    setFunction = F['set/' + q['set']] || F['set/']
    set = setFunction[e,q,g]
    set.map{|u| g[u.uri] ||= u if u.class == E } if set.class == Array

    # unique fingerprint from graph
    [F['graphID'][g],
     F['triplr'][e,q],
     q.has_key?('nocache').do{|_|rand}
    ].h}

  fn 'graph/',->e,q,m{
    triplr = F['triplr'][e,q]
    m.values.map{|r|
      (r.env e.env).graphFromFile m, triplr if r.class == E }}

  fn 'graphID',->g{
    g.sort.map{|u,r|
      [u, r.respond_to?(:m) && r.m]}.h}

  fn 'triplr',->e,q{
    t = q['triplr']
    t && e.respond_to?(t) && t || :triplrMIME }

  # document-set
  fn 'set/',->e,q,_{
    s = []
    s.concat e.docs
    e.pathSegment.do{|p| s.concat p.docs }
    s }

  def triplrMIME &b
    mimeP.do{|mime|
      yield uri,E::Type,(E MIMEtype+mimeP)
      (MIMEsource[mimeP]||
       MIMEsource[mimeP.split(/\//)[0]]).do{|s|
        send *s,&b }}
  end

  def graphFromFile g={}, triplr=:triplrMIME
    g.mergeGraph r(true) if ext=='e' # JSON -> graph
    [:triplrInode,        # filesystem data
     triplr].# format-specific tripleStream emitter
      each{|i| fromStream g,i } # tripleStream -> Graph
    g
  end

  def graph g={}
    docs.map{|d|d.graphFromFile g}  # tripleStream -> graph
    g
  end

end

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

  # Hash -> tripleStream
  def triples
    s = uri
    map{|p,o|
      o.class == Array ? o.each{|o| yield s,p,o} : yield(s,p,o) unless p=='uri'}
  end

end
