#watch __FILE__
class E
=begin
  graph construction is two-pass:

 the first-pass will signify if the second-pass needs to be run. an ETag is be derived from the return-value, ideal fingerprint sources include filestats, mtime checks, extremely trivial SPARQL queries, SHA160 hashes of in-RAM entities.. <http://tools.ietf.org/html/draft-ietf-httpbis-p4-conditional-25#section-2.3>

   second-pass might fetch RDF from a SPARQL store. this lib was developed as an alternative to relying on (large, hard-to-implement, must be running, configured & connectable) SPARQL stores by using the filesystem as much as possible, to experiment with hybrids like SPARQLING up a set of files to be returned in standard Apache-as-static-fileserver fashion, and to webize non-RDF filesystem-content like email, directories, plain-text etc

  triple streams - a source function yields triples up to the caller as it finds them,
  a function providing a block (consumes yielded values) is a sink, both is a filter 
  these can be stacked into pipelines. see the data-massaging stream-processing in feed.rb

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
  def addDocs triplr, host, p=nil, hook=nil, &b
    graph = fromStream({},triplr)
    docs = {}
    graph.map{|u,r|
      e = u.E                 # resource
      doc = e.ef              # doc
      doc.e ||                # exists - we're nondestructive here
      (docs[doc.uri] ||= {}   # init doc-graph
       docs[doc.uri][u] = r   # add to graph
       p && p.map{|p|         # index predicate
         r[p].do{|v|v.map{|o| # values exist?
             e.index p,o}}})} # index triple
    docs.map{|d,g|            # resources in docs
      d = d.E; puts "+doc #{d}"
      d.w g,true              # write
      hook[d,g,host] if hook} # insert-hook
    graph.triples &b if b     # emit triples
    self
  end

  # default protograph - identity < lazy-expandable resource-thunks
  # Resource, Query, Graph -> graphID
  fn 'protograph/',->e,q,g{
     g['#'] = {'uri' => '#'}
    set = (q['set'] && F['set/'+q['set']] || F['set/'])[e,q,g]
    if !set || set.empty?
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

  def graphFromFile g={}
    return unless e
    doc = self
    unless ext=='e' # already native-format
      triplr = @r.do{|r|r.q['triplr'].do{|t| (respond_to? t) && t }} || :triplrMIME
      doc = E '/E/rdf/' + [triplr,uri].h.dive
      unless doc.e && doc.m > m; # freshness check
        graph = {}
        [:triplrInode,triplr].each{|t| fromStream graph, t }
        doc.w graph, true
      end
    end
    g.mergeGraph doc.r true
  end

  def ef;  @ef ||= docBase.a('.e') end

  def graph g={}
    docs.map{|d|d.graphFromFile g}  # tripleStream -> graph
    g
  end

  def docs
    base = docBase
    [(base if pathSegment!='/' && base.e),         # doc-base
     (self if base != self && e && uri[-1]!='/'),  # requested path
     base.glob(".{e,html,n3,nt,owl,rdf,ttl,txt}"), # docs
     ((d? && uri[-1]=='/' && uri.size>1) ? c : []) # trailing slash -> child resources
    ].flatten.compact
  end

  def triplrDoc &f; docBase.glob('#*').map{|s| s.triplrResource &f} end

  def triplrResource; predicates.map{|p| self[p].map{|o| yield uri, p.uri, o}} end

  def triplrJSON
    yield uri, '/application/json', (JSON.parse read) if e
  rescue Exception => e
  end

  def to_json *a
    to_h.to_json *a
  end

  fn Render+'application/json',->d,_=nil{d.to_json}

end

class Hash

  def except *ks
    clone.do{|h|
      ks.map{|k|h.delete k}
      h}
  end

  def graph g
    g.merge!({uri=>self})
  end

  def mergeGraph g
    g.triples{|s,p,o|
      self[s] = {'uri' => s} unless self[s].class == Hash 
      self[s][p] ||= []
      self[s][p].push o unless self[s][p].member? o } if g
    self
  end

  def triples &f
    map{|s,r|
      r.map{|p,o|
        o.class == Array ? o.each{|o| yield s,p,o} : yield(s,p,o) unless p=='uri'} if r.class == Hash
    }
  end

end
