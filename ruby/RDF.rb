#watch __FILE__
class R

  def R.resourceToGraph r, graph # Hash/JSON::Resource to RDF::Graph
    uri = r.R
    r.map{|p,o|
      o.justArray.map{|o|
        graph << RDF::Statement.new(uri,p.R,[R,Hash].member?(o.class) ? o.R : RDF::Literal(o))} unless p=='uri'}
  end

  def R.renderRDF d,f,e # Hash/JSON::Graph to RDF::Writer
    (RDF::Writer.for f).buffer{|w| # init writer
      d.triples{|s,p,o|            # structural triples of Hash::Graph
        s && p && o &&             # with all fields non-nil
        (s = e['REQUEST_URI'] if s == '#' # "this" shorthand-URI
         s = RDF::URI s            # subject-URI
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
  
  def graphResponse graph # RDF::Graph to HTTP::Response
    [200,
     {'Content-Type' => format + '; charset=UTF-8',
      'Triples' => graph.size.to_s,
       'Access-Control-Allow-Origin' => self['HTTP_ORIGIN'].do{|o|o.match(R::HTTP_URI) && o} || '*',
       'Access-Control-Allow-Credentials' => 'true',
     },
     [(format == 'text/html' &&
    q['view'] == 'tabulate') ? H[R::View['tabulate'][]] :
      graph.dump(RDF::Writer.for(:content_type => format).to_sym)]]
  end

  [['application/ld+json',:jsonld],
   ['application/rdf+xml',:rdfxml],
   ['text/plain',:ntriples],
   ['text/turtle',:turtle],
   ['text/n3',:n3]].map{|mime| Render[mime[0]] = ->d,e{R.renderRDF d, mime[1], e}}

  def cacheRDF options = {} # write doc-graphs to fs
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

  def justRDF pass = %w{e jsonld n3 nt owl rdf ttl} # recode non-RDF file as RDF-doc using our triplrs
    if e
      doc = self
      unless pass.member? realpath.do{|p|p.extname.tail}
        doc = R['/cache/RDF/' + (R.dive uri.h) + '.e'].setEnv @r
        unless doc.e && doc.m > m # up-to-date?
          g = {} # doc-graph
          [:triplrMIME,:triplrInode].map{|t| fromStream g, t} # triplize
          doc.w g, true # cache
        end
      end
      doc
    end
  end

  def triplrN3
    RDF::Reader.open(pathPOSIX, :format => :n3, :base_uri => stripDoc){|r|
      r.each_triple{|s,p,o|
        yield s.to_s, p.to_s,[RDF::Node, RDF::URI].member?(o.class) ? R(o) : o.value}}
  end

  def n3; docroot.a '.n3' end

  module Format # Reader class for .e JSON format

    class Format < RDF::Format
      content_type     'application/json+rdf', :extension => :e
      content_encoding 'utf-8'
      reader { R::Format::Reader }
    end

    class Reader < RDF::Reader
      format Format

      def initialize(input = $stdin, options = {}, &block)
        @graph = JSON.parse (input.respond_to?(:read) ? input : StringIO.new(input.to_s)).read
        @env = options[:base_uri].env
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
          fn.call RDF::Statement.new(s.R.setEnv(@env).bindHost, p.R,
            o.class == Hash ? o.R.setEnv(@env).bindHost : (l = RDF::Literal o; l.datatype=RDF.XMLLiteral if p == Content; l))}
      end

      def each_triple &block
        each_statement{|s| block.call *s.to_triple}
      end
    end
  end
end
