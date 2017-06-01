class R
  # graph JSON:
  # {subjURI(str) => {predURI(str) => [objectA..]}}

  # tripleStream -> Graph
  def fromStream m,*i
    send(*i) do |s,p,o|
      m[s] = {'uri' => s} unless m[s].class == Hash 
      m[s][p] ||= []
      m[s][p].push o unless m[s][p].class != Array || m[s][p].member?(o)
    end
    m
  end

  # normalize file handles to RDF
  def justRDF pass = %w{e}
    if pass.member? node.realpath.do{|p|p.extname[1..-1]} # already RDF
      self # return
    else # non RDF, transcode
      h = uri.sha1
      doc = R['/cache/RDF/'+h[0..2]+'/'+h[3..-1]+'.e'].setEnv @r
      doc.w fromStream({},:triplrMIME),true unless doc.e && doc.m > m # cache check
      doc
    end
  end
  
  # file -> Graph
  def loadGraph graph
    return unless e
    justRDF.do{|f| # maybe transcode to RDF
      ((f.r true)||{}). # read JSON file
        triples{|s,p,o| # add triples to graph
        graph[s] ||= {'uri' => s}
        graph[s][p] = (graph[s][p]||[]).justArray.push o
      }}
    graph
  end

  # files -> Graph
  def graph graph = {}
    documents.map{|d|d.loadGraph graph}
    graph
  end

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

  Render['application/json'] = -> graph,_ { graph.to_json }

end

class Hash

  def triples &f
    map{|s,resource|
      resource.map{|p,o|
        o.justArray.map{|o|yield s,p,o} if p != 'uri'}}
  end

  def types
    self[R::Type].justArray.select{|t|t.respond_to? :uri}.map &:uri
  end

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
