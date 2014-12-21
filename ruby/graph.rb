#watch __FILE__
class R
=begin
 Hash/JSON for a subset of RDF,

  {subjURI => {predURI => object}}

  subj/predURI: String

  object:
   Array [object1, object2]
   RDF::URI (URI-identified resource)
   R (our enhanced subclass of RDF::URI)
   Hash with a key named 'uri'
   RDF::Literal
   String

 to emit triples: yield subjURI, predURI, object

=end

  # triplr -> graph (Hash)
  def fromStream m,*i
    send(*i) do |s,p,o|
      m[s] = {'uri' => s} unless m[s].class == Hash 
      m[s][p] ||= []
      m[s][p].push o unless m[s][p].class != Array || m[s][p].member?(o)
    end
    m
  end

  # triplr -> graph (RDF)
  def fromStreamRDF g, *i
    send(*i) do |s,p,o|
      s = R[(lateHost.join s).to_s] # subject
      p = RDF::URI p                # predicate
      o = if [R,Hash].member? o.class
            RDF::URI o.uri     # object URI ||
          else                 # object Literal
            l = RDF::Literal o
            l.datatype=RDF.XMLLiteral if p == Content
            l
          end
      g << (RDF::Statement.new s,p,o)
    end
    g
  end

  # inode(s) -> graph (Hash)
  def graph graph = {}
    fileResources.map{|d| d.nodeToGraph graph}
    graph
  end

  # inode -> graph (Hash)
  def nodeToGraph graph = {}
    justRDF(%w{e}).do{|file|
     graph.mergeGraph file.r true}
    graph
  end

  # triplr -> file(s)
  def triplrCacheJSON triplr, host = 'localhost',  p = nil,  hook = nil, &b
    graph = fromStream({},triplr)    # collect triples
    R.cacheJSON graph, host, p, hook # cache
    graph.triples &b if b            # emit triples
    self
  end

  # graph (Hash) -> file(s)
  def R.cacheJSON graph, host = 'localhost',  p = nil,  hook = nil
    docs = {} # document bin
    graph.map{|u,r| # each resource
     (e = u.R                 # resource URI
      doc = e.jsonDoc         # doc URI
      doc.e ||                # cache hit ||
      (docs[doc.uri] ||= {}   # doc graph
       docs[doc.uri][u] = r   # resource -> graph
       p && p.map{|p|         # index predicates
         r[p].do{|v|v.map{|o| # objects exist?
             e.index p,o}}})) if u} # index
    docs.map{|d,g| # each doc
      d = d.R; puts "<#{d.docroot}>"
      d.w g,true              # cache
      hook[d,g,host] if hook} # indexer
  end

  # graph (RDF) -> file(s)
  def cacheRDF options = {}
    g = RDF::Repository.load self, options
    g.each_graph.map{|graph|
      if graph.named?
        doc = graph.name.n3
        unless doc.e
          doc.dir.mk
          file = doc.pathPOSIX
          RDF::Writer.open(file){|f|f << graph} ; puts "<#{doc.docroot}> #{graph.count} triples"
          options[:hook][doc,graph,options[:hostname]] if options[:hook]
        end
      end}
    g
  end

  # file -> file (Non-RDF -> RDF)
  def justRDF pass = %w{e html jsonld n3 nt owl rdf ttl}  # RDF suffixes
    return unless e                                       # check that source exists
    doc = self                                            # output doc
    unless pass.member? realpath.do{|p|p.extname.tail}    # already readable MIME?
      doc = R['/cache/RDF/'+R.dive(uri.h)+'.e'].setEnv @r # RDF file
      doc.w fromStream({},:triplrMIME),true unless doc.e && doc.m > m # write
    end
    doc
  end

  Mutate = -> g,e {
    e[:Filter].justArray.map{|f|Filter[f].do{|fn| fn[g,e]}} # named filters
    if e[:container] || e.q.has_key?('summary')
      groups = {}
      g.map{|u,r|
        r.types.map{|type| # RDF types
          if v = Abstract[type] # class-summarizer exists
            groups[v] ||= {} # init type-group
            groups[v][u] = r # resource to type-group
          end}}
      groups.map{|fn,gr|fn[g,gr,e]} # per-type summarize
    end}

end

class Array
  def sortRDF env
    sort = (env.q['sort']||'dc:date').expand
    sortType = [R::Size,
                R::Stat+'mtime'].member?(sort) ? :to_i : :to_s
    sort_by{|i|
      ((i.class==Hash && i[sort] || i.uri).justArray[0]||0).
        send sortType}
  end
end

class Hash

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
        o.justArray.map{|o|yield s,p,o} unless p=='uri'} if r.class == Hash}
  end

  def types
    self[R::Type].justArray.map(&:maybeURI).compact
  end

  def resources env
    values.sortRDF env
  end

  def toRDF # graph (Hash) -> graph (RDF)
    graph = RDF::Graph.new
    triples{|s,p,o|
      s = RDF::URI s
      p = RDF::URI p
      o = if [R,Hash].member? o.class
            RDF::URI o.uri
          else
            l = RDF::Literal o
            l.datatype=RDF.XMLLiteral if p == R::Content
            l
          end
      graph << (RDF::Statement.new s,p,o)
    }
    graph
  end

end
