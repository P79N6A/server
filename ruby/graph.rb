#watch __FILE__
class E
=begin
  graph resolution is two-pass

  protograph/
 the first-pass will determine if the second-pass needs to run. an eTag will be derived from the return-value and any graph additions preserved for the next pass. ideal fingerprint sources include filestats, mtime checks, extremely trivial SPARQL queries, SHA160 hashes of in-RAM entities. you can define only a second or first-pass and get default behaviour for the other. for more ideas see <http://tools.ietf.org/html/draft-ietf-httpbis-p4-conditional-25#section-2.3>

  graph/
   a second-pass might query a CBD (concise-bounded description) from a SPARQL store. infod was originally developed as an alternative to fragility & latency of relying on (large, hard-to-implement, must be running, configured & connectable) SPARQL stores by using the filesystem as much as possible, to experiment with hybrids like "touch" a file on successful POSTs so a store only has to be queried occasionally, and to facilitate simply hooking up bits of Ruby code to names rather than try to shoehorn what you're trying to say into some QueryLang where you're additionally without standard library functions necessitating more roundtrips and latency via marshalling/unmarshalling, parsing, loopback network-abstraction, nascent RDF-via-SPARQL-as-ORM-libs.. but go nuts experimenting w/ graph-handlers for this stuff,,i do..

  triple streams are functions which yield triples
  s,p - URI in String , o - Literal or URI (object must respond to #uri such as '/path'.E or {'uri' => '/some.n3'}
  these can be formed into pipelines. the data ingesting/massaging stream-processors in feed.rb are modularized this way

=end

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
  def insertDocs triplr, host, p=[], &b
    graph = fromStream({},triplr)
    docs = {}
    graph.map{|u,r|
      e = u.E                # resource
      doc = e.ef             # doc
      doc.e ||               # exists?
      (docs[doc.uri] ||= {}  # init doc graph
       docs[doc.uri][u] = r  # add to graph
       p.map{|p|             # each indexable property
         r[p].do{|v|         # values exists?
           v.map{|o|         # each value
             e.index p,o}}})}# add to property index 
    docs.map{|doc,g|
      d = doc.E
      if !d.e
        d.w g, true   # write doc
        d.roonga host # text index
        puts "#{doc} < #{g.keys.join ' '}"
      end}
    graph.triples &b if b # emit the triples
    self
  end

  # default protograph - identity + resource-thunks
  # Resource, Query, Graph -> graphID
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
  # to use a different default-graph function (w/o patching here, or querystring param), define a GET handler on / (or a subdir),
  # update configuration such as q['graph'] = 'hexastore' and return false or call #response..
  fn 'graph/',->e,q,m{
    # force thunks
    m.values.map{|r|(r.env e.env).graphFromFile m if r.class == E }
    # cleanup unexpanded thunks
    m.delete_if{|u,r|r.class==E}}

  fn 'filter/set',->e,m,r{
    # filter to RDFs set-members, gone will be:
    # data about docs containing the data
    # other fragments in a doc not matching search when indexed per-fragment
    f = m['#'].do{|c| c[RDFs+'member'].do{|m| m.map &:uri }} || [] # members
    m.keys.map{|u| m.delete u unless f.member? u}} # trim

  def graphFromFile g={}
    if !e
      puts "missing file! "+d
      return
    end
    _ = self
    triplr = @r.do{|r|
                    r.q['triplr'].do{|t|
                          respond_to?(t) && t }} || :triplrMIME
    unless ext=='e' # native graph-format
      _ = E '/E/rdf/' + [triplr,uri].h.dive
      unless _.e && _.m > m;       # up to date?
        e = {} ; puts "< #{uri}"
        [:triplrInode,triplr].each{|t| fromStream e, t }
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
