#watch __FILE__
class R
=begin
 methods to enable usage of inbuilt Hash and JSON classes/methods for a subset of RDF (no blank-nodes, typed-literals are limited to JSON datatypes + HTML/XMLLiteral)

  {subjURI => {predURI => object}}

  subject + predicate are strings containing URIs

  object varies, can be:
   RDF::URI  (URI-identified resource)
   R (our sub-class of RDF::URI with additional POSIX-oriented name-functionality)
   Hash, in format {'uri' => objURI}
   Literal RDF::Literal or plain string

 non-RDF triplr "streams" are emitted with: yield subjURI, predURI, object

=end

  def fromStream m,*i # collect a triplestream's output into a Hash::Graph
    send(*i) do |s,p,o|
      m[s] = {'uri' => s} unless m[s].class == Hash 
      m[s][p] ||= []
      m[s][p].push o unless m[s][p].class != Array || m[s][p].member?(o)
    end; m
  end

  def graph graph = {} # load resource to graph
    fileResources.map{|d| d.fileToGraph graph}
    graph
  end

  def fileToGraph graph = {} # load file to graph
    justRDF(%w{e}).do{|file|
     graph.mergeGraph file.r true}
    graph
  end

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
      hook[d,g,host] if hook} # write-hook
  end

  # save JSON docs of resources in triple-stream
  def triplrCacheJSON triplr, host = 'localhost',  p = nil,  hook = nil, &b
    graph = fromStream({},triplr)    # collect triples
    R.cacheJSON graph, host, p, hook # cache
    graph.triples &b if b            # emit triples
    self
  end

  def jsonDoc; docroot.a '.e' end

  def triplrJSON
    yield uri, RDFns + 'JSON', r(true) if e
  rescue Exception => e
    puts "triplrJSON #{e}"
  end

  def R.renderRDF d,f,e # Hash::Graph -> RDF::Serialization
    (RDF::Writer.for f).buffer{|w| # init writer
      d.triples{|s,p,o|            # structural triples of Hash::Graph
        s && p && o &&             # all fields non-nil
        (s = RDF::URI s            # subject-URI
         p = RDF::URI p            # predicate-URI
         o = (if [R,Hash].member? o.class
                RDF::URI o.uri     # object URI ||
              else                 # object Literal
                l = RDF::Literal o
                l.datatype=RDF.XMLLiteral if p == Content
                l
              end) rescue nil
         (w << (RDF::Statement.new s,p,o) if o) rescue nil )}}
  end

  [['application/ld+json',:jsonld], # per-MIME render lambdas
   ['application/rdf+xml',:rdfxml],
   ['text/plain',:ntriples],
   ['text/turtle',:turtle],
   ['text/n3',:n3]].map{|mime|
    Render[mime[0]] = ->d,e{
      R.renderRDF d, mime[1], e}}

  def to_json *a
    {'uri' => uri}.to_json *a
  end

  Render['application/json'] = -> d,e { JSONview[e.q['view']].do{|f|f[d,e]} || d.to_json }

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

  def resourcesOfType type
    values.select{|resource|
      resource[R::Type].do{|types|
        types.justArray.map(&:maybeURI).member? type }}
  end

end
