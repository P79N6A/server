#watch __FILE__
class R
=begin miniRDF - a subset of RDF which trivially works as JSON

 Hash/JSON
  {subject => {predicate => object}}

 types:
  subject: String
  predicate: String
  object (one of):
   Array [objectA, objectB..]
   RDF::URI
   RDF::Literal
   R (subclass of RDF::URI)
   Hash with 'uri' key
   String

 Streams
  yield subject, predicate, object

=end

  # triples -> graph
  def fromStream m,*i
    send(*i) do |s,p,o|
      m[s] = {'uri' => s} unless m[s].class == Hash 
      m[s][p] ||= []
      m[s][p].push o unless m[s][p].class != Array || m[s][p].member?(o)
    end
    m
  end

  # inode -> inode (Non-RDF -> RDF)
  def justRDF pass = RDFsuffixes
    return unless e                                    # check that source exists
    doc = self                                         # out doc
    unless pass.member? realpath.do{|p|p.extname.tail} # already desired MIME?
      doc = R['/cache/RDF/'+R.dive(uri.h)+'.e'].setEnv @r # cached transcode
      unless doc.e && doc.m > m                           # cache valid
        graph = {}                                        # update cache
        fromStream graph, :triplrFile if file?
        fromStream graph, :triplrMIME
        doc.w graph, true
      end
    end
    doc
  end

  # inode -> graph
  def nodeToGraph graph
    base = @r.R.join(stripDoc) if @r    # base-URI
    justRDF(%w{e}).do{|f|               # JSON-format doc
      (f.r(true)||{}).triples{|s,p,o|         # triple
        s = base.join(s).to_s if @r     # subject URI
        if @r && o.class==Hash && o.uri # object URI
          o['uri'] = base.join(o.uri).to_s
        end
        graph[s] ||= {'uri' => s}       # resource
        graph[s][p] ||= []              # predicate
        graph[s][p].push o unless graph[s][p].member? o
      }}
    graph
  end
  
  # URI -> graph
  def graph graph = {}
    fileResources.map{|d|d.nodeToGraph graph}
    graph
  end

  # triples -> fs-store
  def triplrStoreJSON triplr, host = 'localhost',  p = nil,  hook = nil, &b
    graph = fromStream({},triplr) # collect triples
    R.store graph, host, p, hook  # cache
    graph.triples &b if b         # emit triples
    self
  end

  # graph -> fs-store
  def R.store graph, host = 'localhost',  p = nil,  hook = nil
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

  # URI -> fs-store
  def store options = {}
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

  def triples &f
    map{|s,r|
      r.map{|p,o|
        o.justArray.map{|o|yield s,p,o} unless p=='uri'}}
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
      graph << (RDF::Statement.new s,p,o)}
    graph
  end

end
