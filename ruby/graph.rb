#watch __FILE__
class R
=begin
 use inbuilt Hash and JSON classes for a subset of RDF - literal types are limited to JSON , RDF:HTML

  {subjURI => {predURI => object}},  key-names are URI strings

  object varies, can be:
   RDF::URI (URI-identified resource)
   R (this subclass of RDF::URI)
   Hash with 'uri' key
   Literal RDF::Literal or plain string

 emit triple-streams: yield subjURI, predURI, object

=end

  def fromStream m,*i # triplr -> graph
    send(*i) do |s,p,o|
      m[s] = {'uri' => s} unless m[s].class == Hash 
      m[s][p] ||= []
      m[s][p].push o unless m[s][p].class != Array || m[s][p].member?(o)
    end; m
  end

  def graph graph = {} # file(s) -> graph
    fileResources.map{|d| d.fileToGraph graph}
    graph
  end

  def fileToGraph graph = {} # file -> graph
    justRDF(%w{e}).do{|file|
     graph.mergeGraph file.r true}
    graph
  end

  # graph -> file(s)
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

  # triplr -> file(s)
  def triplrCacheJSON triplr, host = 'localhost',  p = nil,  hook = nil, &b
    graph = fromStream({},triplr)    # collect triples
    R.cacheJSON graph, host, p, hook # cache
    graph.triples &b if b            # emit triples
    self
  end

  # RDF::Repository -> file(s)
  def cacheRDF options = {}
    g = RDF::Repository.load self, options
    g.each_graph.map{|graph|
      if graph.named?
        doc = graph.name.n3
        unless doc.e
          doc.dir.mk
          RDF::Writer.open(doc.pathPOSIX){|f|f << graph} ; puts "<#{doc.docroot}> #{graph.count} triples"
          options[:hook][doc,graph,options[:hostname]] if options[:hook]
        end
      end}
    g
  end

  # replace non-RDF fs-references w/ RDF::Reader readable - long-tail for MIMEs w/o a Reader class
  def justRDF pass = %w{e jsonld n3 nt owl rdf ttl}            # RDF suffixes
    return unless e                                            # check that source exists
    doc = self                                                 # output doc
    unless pass.member? realpath.do{|p|p.extname.tail}         # already a good MIME?
      doc = R['/cache/RDF/' + (R.dive uri.h) + '.e'].setEnv @r # derived RDF file
      unless doc.e && doc.m > m                                # up-to-date?
        g = {}                                                 # blank graph
        [:triplrMIME,:triplrInode].map{|t| fromStream g, t}    # triples -> graph
        doc.w g, true                                          # write
      end
    end
    doc
  end

  def triplrN3
    RDF::Reader.open(pathPOSIX, :format => :n3, :base_uri => stripDoc){|r|
      r.each_triple{|s,p,o|
        yield s.to_s, p.to_s,[RDF::Node, RDF::URI].member?(o.class) ? R(o) : o.value}}
  end

  # graph -> MIME-format
  def R.renderRDF d,f,e
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

  [['application/ld+json',:jsonld], # per-MIME renderer-lambdas
   ['application/rdf+xml',:rdfxml],
   ['text/plain',:ntriples],
   ['text/turtle',:turtle],
   ['text/n3',:n3]].map{|mime|
    Render[mime[0]] = ->d,e{
      R.renderRDF d, mime[1], e}}

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
