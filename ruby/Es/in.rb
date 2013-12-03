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

  def insertDocs triplr, h=nil, p=[], &b
    graph = fromStream({},triplr)
    graph.map{|u,r| # stream -> graph
      e = u.E           # resource
      j = e.ef          # doc
      j.e ||            # exists?
      (j.w({u=>r},true) ;puts' < '+u # insert doc
       p.map{|p|        # each indexable property
     r[p].do{|v|        # values exists?
       v.map{|o|        # each value
        e.index p,o}}}  # property index 
       e.roonga h if h  # full-text index
       )}
    graph.triples &b if b
    self
  end

  # default proto-graph
  #   mint graph identifier
  #   any graph setup (:g variable mutation) is preserved
  fn 'protograph/',->e,q,g{
    set = (F['set/' + q['set']] || F['set/'])[e,q,g]
    set.map{|u| g[u.uri] ||= u if u.class == E } if set.class == Array
    # unique fingerprint for graph
    [F['docsID'][g],
     F['triplr'][e,q],
     q.has_key?('nocache').do{|_|rand}
    ].h}

  # an almost-empty graph to defeat 404
  fn 'protograph/_',->d,_,m{
    m[d.uri] = {}
    rand.to_s.h}

  # default graph
  #  filesystem storage
  fn 'graph/',->e,q,m{
    triplr = F['triplr'][e,q]
    m.values.map{|r|
      (r.env e.env).graphFromFile m, triplr if r.class == E }}

  fn 'docsID',->g{
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
