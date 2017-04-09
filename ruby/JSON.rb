class R
  #  graph JSON:
  #  {subjURI(str) => {predURI(str) => [objectA..]}}

  # tripleStream -> Graph
  def fromStream m,*i
    send(*i) do |s,p,o|
      m[s] = {'uri' => s} unless m[s].class == Hash 
      m[s][p] ||= []
      m[s][p].push o unless m[s][p].class != Array || m[s][p].member?(o)
    end
    m
  end

  # normalize set to RDF docs only
  def justRDF pass = RDFsuffixes
    if pass.member? realpath.do{|p|p.extname.tail} # already RDF
      self # return
    else # non RDF, transcode
      doc = R['/cache/RDF/'+R.dive(uri.h)+'.e'].setEnv @r
      doc.w fromStream({},:triplrMIME),true unless doc.e && doc.m > m # cache check
      doc
    end
  end
  
  # file -> Graph
  def loadGraph graph
    return unless e
    base = @r.R.join(stripDoc) if @r
    justRDF(%w{e}).do{|f|
      ((f.r true) || {}). # load graph
        triples{|s,p,o|   # foreach triple
        if base           # resolve ID
          s = base.join(s).to_s
          o['uri'] = base.join(o.uri).to_s if o.class==Hash && o.uri          
        end
        graph[s] ||= {'uri' => s}
        graph[s][p] = (graph[s][p]||[]).justArray.push o}}
    graph
  end

  # files -> Graph
  def graph graph = {}
    fileResources.map{|d|
      d.loadGraph graph}
    graph
  end

  def pack # consolidate native docs in container to a single file (nonrecursive)
    return unless directory?
    res = (child '*.e').glob   # find children
    return unless res.size > 1 # already zero/one docs, done
    graph = {}                 # graph
    res.map{|r|r.loadGraph graph; r.delete} # load
    child('index.e').w graph, true # write doc
    self
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
