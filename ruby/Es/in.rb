class E

  # Graph -> tripleStream -> Graph
  def fromStream m,*i
    send(*i) do |s,p,o|
      m[s] = {'uri' => s} unless m[s].class == Hash 
      m[s][p] ||= []
      m[s][p].push o unless m[s][p].member? o
    end; m
  end

  # tripleStream pipeline into graph
  fn 'graph/|',->e,_,m{
    [e,e.pathSegment].map{|e|
      e.fromStream m, *_['|'].split(/,/)}}

  # placeholder graph (not empty)
  fn 'protograph/_',->d,_,m{
    m[d.uri] = {}
    rand.to_s.h}

  fn 'protograph/',->e,q,g{
    set = F['set/'+q['set']][e,q,g]
    set.map{|u| g[u.uri] ||= u }
    # identify
    [F['graphID'][g], F['triplr'][e,q]].h}

  # graph identifier - for filesystem-based resultsets
  fn 'graphID',->g{
    g.sort.map{|u,r|
      [u, r.respond_to?(:m) && r.m]}.h}

  fn 'graph/',->e,q,m{
    triplr = F['triplr'][e,q]
    m.values.map{|r|
      (r.env e.env).graphFromFile m, triplr if r.class == E }}

  fn 'triplr',->e,q{
    t = q['triplr']
    t && e.respond_to?(t) && t ||
    :triplrMIME 
  }

  # document-set
  fn 'set/',->e,q,_{
    s = []
    s.concat e.docs
    s.concat e.pathSegment.docs
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

  # self -> tripleStream
  def triples
    s = uri
    map{|p,o|
      o.class == Array ? o.each{|o| yield s,p,o} : yield(s,p,o) unless p=='uri'}
  end

end
