class R
=begin
  JSON graph

  {subject => {predicate => object}}

  subject+predicate are URIs in a text field
  object is R or RDF::URI or RDF::Literal or JSON literal or
   Hash/Object with 'uri' key or
   [objectA, objectB..]

=end

  # Stream -> Graph
  def fromStream m,*i
    send(*i) do |s,p,o|
      m[s] = {'uri' => s} unless m[s].class == Hash 
      m[s][p] ||= []
      m[s][p].push o unless m[s][p].class != Array || m[s][p].member?(o)
    end
    m
  end

  # URI -> Graph
  def graph graph = {}
    fileResources.map{|d|d.nodeToGraph graph}
    graph
  end

  # file -> Graph
  def nodeToGraph graph
    return unless e
    base = @r.R.join(stripDoc) if @r
    justRDF(%w{e}).do{|f|
      ((f.r true) || {}). # load graph
        triples{|s,p,o|   # foreach triple
        if base           # base URI
          s = base.join(s).to_s     # resolve subject-URI
          if o.class==Hash && o.uri # resolve object-URI
            o['uri'] = base.join(o.uri).to_s
          end
        end
        graph[s] ||= {'uri' => s}
        graph[s][p] = (graph[s][p]||[]).justArray.push o}}
    graph
  end

  # Machine-In-The-Middle of triple-stream, caching on pass-through
  # non-destructive, only writes to new identifier
  def triplrCache triplr, host = 'localhost', properties = nil, indexer = nil, &b
    graph = fromStream({},triplr) # bunch triples
    R.store graph, host, properties, indexer # cache
    graph.triples &b if b # emit triples
    self
  end

  # Graph, host, predicates to index, indexer-lambda -> file(s) 
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
      d = d.R
      d.w g, true                   # write
      indexer[d,g,host] if indexer} # index-update handler
  end

  # URI -> file
  def store options = {}
    g = RDF::Repository.load self, options
#    puts "store #{g.size} triples from #{uri}"
    g.each_graph.map{|graph|
      if graph.named?
#        puts "graph #{graph.name}"
        doc = graph.name.ttl
        unless doc.e
          doc.dir.mk
          file = doc.pathPOSIX
#          puts "storage in #{file}"
          RDF::Writer.open(file){|f|f << graph}
          options[:hook][doc,graph,options[:hostname]] if options[:hook]
        end
      end}
    g
  rescue Exception => e
    puts uri,e.class,e.message
    g
  end

  # Reader class for RDF library
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

  # file-reference (non-RDF file) ->  file-reference (RDF file)
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
    compact.sort_by{|i|
      ((if i.class==Hash
        if sort == 'uri'
          i[R::Label] || i.uri
        else
          i[sort]
        end
       else
         i.uri
        end).justArray[0]||0).send sortType}.send(env.q.has_key?('ascending') ? :id : :reverse)
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

  # convert to RDF::Graph
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
