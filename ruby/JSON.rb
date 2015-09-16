class R
=begin RDF-subset in JSON. why not just RDF.rb and JSON-LD? we use that too. this is for speed, implementation-simplicity, and because it existed before RDF.rb and we still like using it sometimes

 Graph: Hash
  {subject => {predicate => object}}
 Stream:
   produce:
  yield subject, predicate, object
   consume:
  do |subject,predicate,object|

  *subject: String
  *predicate: String
  *object: URI or Literal or
   List/Array [objectA, objectB..]

  *URI
   RDF::URI
   R (our resource-class)
   Hash with 'uri' key

  *Literal
   RDF::Literal
   String Integer Float

=end

  # Stream -> JSONGraph
  def fromStream m,*i
    send(*i) do |s,p,o|
      m[s] = {'uri' => s} unless m[s].class == Hash 
      m[s][p] ||= []
      m[s][p].push o unless m[s][p].class != Array || m[s][p].member?(o)
    end
    m
  end

  # URI -> JSONGraph
  def graph graph = {}
    fileResources.map{|d|d.nodeToGraph graph}
    graph
  end

  # file -> JSONGraph
  def nodeToGraph graph
    return unless e
    base = @r.R.join(stripDoc) if @r
    justRDF(%w{e}).do{|f| # RDF doc
      if @r && @r[:container] && file? # contained file
        # add file-metadata
        if self != f # skip native-storage
          s = stripDoc.uri # strip to generic-resource
          s = base.join(s).to_s if base # resolve URI
          graph[s] ||= {'uri' => s} # graph
          mt = f.mtime
          graph[s][Size] = f.size
          graph[s][Mtime] = mt.to_i
          graph[s][Date] = mt.iso8601
          graph[s][Type] ||= R[Resource]
        end
      end
      ((f.r true) || {}). # load graph
        triples{|s,p,o|   # foreach triple
        if base           # base URI
          s = base.join(s).to_s     # resolve subject-URI
          if o.class==Hash && o.uri # resolve object-URI
            o['uri'] = base.join(o.uri).to_s
          end
        end
        graph[s] ||= {'uri' => s}
        graph[s][p] = (graph[s][p]||[]).justArray.push o}} # unless graph[s][p].member? o # dedupe
    graph
  end

  # wrapper triplr - caches and indexes previously-unseen resources as a side-effect
  # non-destructive: a new identifier is required for cache-write
  # Stream -> file(s) -> Stream
  def triplrCache triplr, host = 'localhost', properties = nil, indexer = nil, &b
    graph = fromStream({},triplr) # bunch triples
    R.store graph, host, properties, indexer # cache
    graph.triples &b if b # emit triples
    self
  end

  # JSONGraph -> file(s). supply list of predicates to index, and/or arbitrary indexer-lambda
  def R.store graph, host = 'localhost', p = nil, indexer = nil
    docs = {} # document bin
    graph.map{|u,r| # each resource
     (e = u.R                 # resource URI
      doc = e.jsonDoc         # doc URI
      doc.e ||                # cache hit ||
      (docs[doc.uri] ||= {}   # doc graph
       docs[doc.uri][u] = r   # resource -> graph
       p && p.map{|p|         # index predicates
         r[p].do{|v|v.map{|o| # objects exist?
             e.index p,o}}})) if u} # index property
    docs.map{|d,g| # each doc
      d = d.R; puts "<#{d.docroot}>"
      d.w g,true                    # write
      indexer[d,g,host] if indexer} # index-update handler
  end

  # URI -> file
  def store options = {}
    g = RDF::Repository.load self, options
    g.each_graph.map{|graph|
      if graph.named?
        doc = graph.name.n3
        unless doc.e
          doc.dir.mk
          file = doc.pathPOSIX
          RDF::Writer.open(file){|f|f << graph}
          puts "#{doc.docroot} #{graph.count}"
          options[:hook][doc,graph,options[:hostname]] if options[:hook]
        end
      end}
    g
  end

  # RDF::Reader for JSON format
  module Format

    class Format < RDF::Format
      content_type     'application/json+rdf', :extension => :e
      content_encoding 'utf-8'
      reader { R::Format::Reader }
    end

    class Reader < RDF::Reader
      format Format

      def initialize(input = $stdin, options = {}, &block)
        @graph = JSON.parse (input.respond_to?(:read) ? input : StringIO.new(input.to_s)).read
        @base = options[:base_uri]
        if block_given?
          case block.arity
          when 0 then instance_eval(&block)
          else block.call(self)
          end
        end
        nil
      end

      def each_statement &fn
        @graph.triples{|s,p,o|
          fn.call RDF::Statement.new(
                    @base.join(s),
                    RDF::URI(p),
                    o.class==Hash ? @base.join(o['uri']) : (l = RDF::Literal o
                                                         l.datatype=RDF.XMLLiteral if p == Content
                                                         l)
                  )}
      end

      def each_triple &block
        each_statement{|s| block.call *s.to_triple}
      end

    end

  end

  def to_json *a
    {'uri' => uri}.to_json *a
  end

  Render['application/json'] = -> d,e { d.to_json }

  # file-reference (non-RDF) ->  file-reference (RDF)
  def justRDF pass = RDFsuffixes
    if pass.member? realpath.do{|p|p.extname.tail} # already RDF
      self # unchanged
    else
      doc = R['/cache/RDF/'+R.dive(uri.h)+'.e'].setEnv @r # cache URI
      doc.w fromStream({},:triplrMIME),true unless doc.e && doc.m > m # cache
      doc # mapped doc
    end
  end

end

class Array
  def sortRDF env
    sort = (env.q['sort']||'dc:date').expand
    sortType = [R::Size, R::Stat+'mtime'].member?(sort) ? :to_i : :to_s
    orient = env.q.has_key?('reverse') ? :reverse : :id
    compact.sort_by{|i|
      ((if i.class==Hash
        if sort == 'uri'
          i[R::Label] || i.uri
        else
          i[sort]
        end
       else
         i.uri
        end).justArray[0]||0).send sortType}.send(orient)
  end
end

class Hash

  def triples &f
    map{|s,r|
      (r||{}).map{|p,o|
        o.justArray.map{|o|yield s,p,o} unless p=='uri'}}
  end

  def types
    self[R::Type].justArray.map(&:maybeURI).compact
  end

  def resources env
    values.sortRDF env
  end

  # JSONGraph -> RDF::Graph
  def toRDF base=nil
    graph = RDF::Graph.new
    triples{|s,p,o|
      s = if base
            base.join s
          else
            RDF::URI s
          end
      p = RDF::URI p
      o = if [R,Hash].member?(o.class) && o.uri
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
