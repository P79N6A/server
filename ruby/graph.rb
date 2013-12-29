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
    # expand to set of filesystem resources
    set = (q['set'] && F['set/'+q['set']] || F['set/'])[e,q,g]
    # link resource-refs
    set.map{|u| g[u.uri] ||= u if u.class == E } if set.class == Array
    F['docsID'][g,q]}

  # default graph (filesystem backed)
  # to change default graph w/o querystring or source-hacking,
  # define a GET handler with non-default env: q['graph'] = 'hexastore'
  fn 'graph/',->e,q,m{
    t = q['triplr'].do{|t|(e.respond_to? t) && t} || :triplrMIME
    m.values.map{|r|
      # graph from resource references
      (r.env e.env).graphFromFile m, t if r.class == E }}

  # document-set as used in default protograph
  fn 'set/',->e,q,g{
    s = []
    s.concat e.docs
    e.pathSegment.do{|p| s.concat p.docs }
    unless s.empty?
      # set metadata
      g[e.env['REQUEST_URI']] = {
        RDFs+'member' => s, # links to facilitate jumping between data-browser and classic HTML views
        DC+'hasFormat' => %w{text/n3 text/html}.map{|m| E('http://'+e.env['SERVER_NAME']+e.env['REQUEST_PATH']+'?format='+m) unless e.env.format == m}.compact,
      }
    end
    s }

  def graphFromFile g={}, triplr=:triplrMIME
    _ = self
    unless ext=='e' # native graph-format already
      # construct native graph if missing or stale
      _ = E '/E/graph/' + uri.h.dive
      unless _.e && _.m > m;  e = {}
        puts "< #{uri}"
        [:triplrInode, triplr].each{|t| fromStream e, t }
        _.w e, true
      end
    end
    g.mergeGraph _.r true
  end

  def graph g={}
    docs.map{|d|d.graphFromFile g}  # tripleStream -> graph
    g
  end

end
