#watch __FILE__
class E

  # triple streams (yield s,p,o)
  # s,p - URI as String
  # o URI ? E class : anything

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
   side-effect of import/indexing to knowledgebase
=end
  def insertDocs triplr, h=nil, p=[], &b
    graph = fromStream({},triplr)
    graph.map{|u,r| # stream -> graph
      e = u.E           # resource
      j = e.ef          # doc
      j.e ||            # exists?
      (j.w({u=>r},true) ;puts '< '+u # insert doc
       p.map{|p|        # each indexable property
     r[p].do{|v|        # values exists?
       v.map{|o|        # each value
        e.index p,o}}}  # property index 
      e.roonga h if h)} # full-text index
    graph.triples &b if b # emit the triples
    self
  end

  # default "protograph" - identity + resource-thunks
  fn 'protograph/',->e,q,g{
     g['#'] = {'uri' => '#'}
    set = (q['set'] && F['set/'+q['set']] || F['set/'])[e,q,g]
    if set.empty?
      g.delete '#'
    else
      g['#'][RDFs+'member'] = set
      g['#'][Type] = E[HTTP+'Response']
      set.map{|u| g[u.uri] = u } # thunk
    end
    F['docsID'][g,q]}

  # default resource-set
  fn 'set/',->e,q,g{
    s = []
    s.concat e.docs
    e.pathSegment.do{|p| s.concat p.docs }
    # day-dir hinted pagination
    e.env['REQUEST_PATH'].match(/(.*?\/)([0-9]{4})\/([0-9]{2})\/([0-9]{2})(.*)/).do{|m|
      u = g['#']
      t = ::Date.parse "#{m[2]}-#{m[3]}-#{m[4]}"
      pp = m[1] + (t-1).strftime('%Y/%m/%d') + m[5]
      np = m[1] + (t+1).strftime('%Y/%m/%d') + m[5]
      u[Prev] = {'uri' => pp} if pp.E.e || E['http://' + e.env['SERVER_NAME'] + pp].e
      u[Next] = {'uri' => np} if np.E.e || E['http://' + e.env['SERVER_NAME'] + np].e }
    s }

  # fs-derived ID for a resource-set
  fn 'docsID',->g,q{
   [q.has_key?('nocache').do{|_|rand},
     g.sort.map{|u,r|
       [u, r.respond_to?(:m) && r.m]}].h }

  # default graph (filesystem store)
  # to change default graph-constructor update env q['graph'] = 'hexa store' (or overwrite this function)
  # ie define a GET handler on / or a subdir, update env and return false
  fn 'graph/',->e,q,m{
    # force thunks
    m.values.map{|r|(r.env e.env).graphFromFile m if r.class == E }
    # cleanup unexpanded thunks
    m.delete_if{|u,r|r.class==E}
    s = m['#'] ||= {} # add links to varied formats
    s[DC+'hasFormat'] = %w{text/n3 application/ld%2Bjson}.map{|m|E('http://'+e.env['SERVER_NAME']+e.env['REQUEST_PATH']+'?format='+m)}}

  fn 'filter/set',->e,m,r{
    # filter to RDFs set-members, gone will be:
    # data about docs containing the data
    # other fragments in a doc not matching search when indexed per-fragment
    f = m['#'].do{|c| c[RDFs+'member'].do{|m| m.map &:uri }} || [] # members
    m.keys.map{|u| m.delete u unless f.member? u}} # trim

  def graphFromFile g={}
    _ = self
    triplr = @r.do{|r|
                    r.q['triplr'].do{|t|
                          respond_to?(t) && t }} || :triplrMIME
    unless ext=='e' # native graph-format already
      # construct native graph if missing or stale
      _ = E '/E/rdf/' + [triplr,uri].h.dive
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
