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
  fn 'graph/|',->e,_,m{
    [e,e.pathSegment].map{|e|
      e.fromStream m, *_['|'].split(/,/)}}

  def E.graphFromStream s
    fn 'graph/'+s.to_s,->e,_,m{e.fromStream m, s}    
  end

  # trivial non-404 graph
  fn 'graph/_',->d,_,m{ m[d.uri] = {} }

  # base graph identifier - filesystem-backed
  # @set option if you just want a different set of docs but all the normal caching/graph-expansion
  fn 'graphID/',->e,q,g{                puts "graphID #{e.uri}"
    set = F['set/'+q['set']][e,q,g]
    # populate resource-thunks
    set.map{|u|g[u.uri] ||= u }
    F['graphID'][g]}

  # identifier from graph skeleton
  fn 'graphID',->g{
    g.sort.map{|u,r|
      [u, r.respond_to?(:m) && r.m]}.h}

  # base graph-expansion
  fn 'graph/',->e,q,m{
    puts "graph #{e.uri} #{m.keys}"
    m.values.map{|r|
      # expand resource-pointers to graph
      (r.env e.env).graphFromFile m if r.class == E }}

  # document-set
  fn 'set/',->e,q,_{
    s = []
    s.concat e.docs
    s.concat e.pathSegment.docs # path on all domains
    puts "set #{s}" if q.has_key? 'debug'
    s }

  def triplrMIMEdispatch &b
    mimeP.do{|mime|
      yield uri,E::Type,(E MIMEtype+mimeP)
      (MIMEsource[mimeP]||
       MIMEsource[mimeP.split(/\//)[0]]).do{|s|
        send *s,&b }}
  end

  def graphFromFile g={}, triplr=:triplrMIMEdispatch
    puts "triplr #{triplr}"
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
