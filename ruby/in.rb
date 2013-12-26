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

=begin
 * stream triples into graph (memory)
 * import missing resources to store (fs)
 * behave as normal triplr to caller, with
   side-effect of import/indexing to kb

=end
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
      e.roonga h if h)} # full-text index
    graph.triples &b if b # emit the triples
    self
  end

  # default "protograph"
  # a graph-identifier (for cache, conditional-response, etc) is returned
  # any graph population is preserved after this function exits
  fn 'protograph/',->e,q,g{
    # expand to set of resources
    set = (q['set'] && F['set/'+q['set']] || F['set/'])[e,q,g]
    # link resource-thunks
    set.map{|u| g[u.uri] ||= u if u.class == E } if set.class == Array

    # identifier
    [F['docsID'][g],
     F['triplr'][e,q],
     q.has_key?('nocache').do{|_|rand}
    ].h}

  # default graph (filesystem backed)
  # to change default graph w/o querystring or source-hacking,
  # define a GET handler which updates env: q['graph'] = 'hexastore'
  fn 'graph/',->e,q,m{ triplr = F['triplr'][e,q]
    m.values.map{|r|
      # expand resource thunks
      (r.env e.env).graphFromFile m, triplr if r.class == E }}

  # unique ID for this set of docs
  # ~= Apache ETag-generation
  fn 'docsID',->g{
    g.sort.map{|u,r|
      [u, r.respond_to?(:m) && r.m]}.h}

  # allow overriding of MIME-derived triplr
  fn 'triplr',->e,q{
    t = q['triplr']
    t && e.respond_to?(t) && t || :triplrMIME }

  # default document-set
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
    [:triplrInode, # filesystem triples
     triplr]. # format-specific triples
      each{|i| fromStream g,i } # tripleStream -> Graph
    g
  end

  def graph g={}
    docs.map{|d|d.graphFromFile g}  # tripleStream -> graph
    g
  end

end
