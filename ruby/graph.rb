#watch __FILE__
class R
=begin a minimal RDF-subset in native-types w/o RDF.rb dependency/overhead (fast, fun, easier(maybe?))
 Graph: Hash
  {subject* => {predicate* => object*}}
 Stream:
  yield subject*, predicate*, object*

  *subject: String
  *predicate: String
  *object: URI* or Literal* or
   List (each member creates a triple)
    [objectA, objectB..]

  *URI
   RDF::URI
   R (our resource-class)
   Hash with 'uri' key

  *Literal
   RDF::Literal
   String Integer Float

   stream-functions that both consume (provide a "block") and produce (yield) can be combined in pipelines
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

  # File(notRDF) -> File(RDF) (via MIME-specific emitter)
  def justRDF pass = RDFsuffixes
    if pass.member? realpath.do{|p|p.extname.tail} # already RDF
      self # unchanged
    else
      doc = R['/cache/RDF/'+R.dive(uri.h)+'.e'].setEnv @r # cache URI
      doc.w fromStream({},:triplrMIME),true unless doc.e && doc.m > m # update cache
      doc # derived doc
    end
  end

  # File -> Graph
  def nodeToGraph graph
    return unless e
    base = @r.R.join(stripDoc) if @r
    justRDF(%w{e}).do{|f| # RDF doc
      if @r && @r[:container] && file? # contained file
        if self != f# skip internal-storage (.e)
          s = stripDoc.uri # point to generic-resource
          s = base.join(s).to_s if base # expand relative-URI
          graph[s] ||= {'uri' => s} # resource to graph
          [Type,Size,Mtime,Date].map{|p|graph[s][p] ||= []} # meta fields
          mt = f.mtime
          graph[s][Size].push f.size
          graph[s][Mtime].push mt.to_i
          graph[s][Date].push mt.iso8601
          graph[s][Type].push R[Resource]
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
        graph[s][p] ||= []
        graph[s][p].push o}} # unless graph[s][p].member? o # dedupe
    graph
  end
  
  # URI -> Graph
  def graph graph = {}
    fileResources.map{|d|d.nodeToGraph graph}
    graph
  end

  # Stream -> doc(s)
  def triplrStoreJSON triplr, host = 'localhost',  p = nil,  hook = nil, &b
    graph = fromStream({},triplr) # collect triples
    R.store graph, host, p, hook  # cache
    graph.triples &b if b         # emit triples
    self
  end

  # Graph -> doc(s)
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

  # RDF::Reader for our format
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
        end).justArray[0]||0).send sortType}
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

  # Hash graph -> RDF Graph
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
