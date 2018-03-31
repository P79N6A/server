class Hash

  # cast to WebResource (reversible)
  def R
    WebResource.new(uri).data self
  end
  # URI accessor method
  def uri
    self["uri"]
  end

end
class WebResource
  module JSON
    include URIs
    def [] p; (@data||{})[p].justArray end
    def data d; @data = (@data||{}).merge(d); self end
    def types; @types ||= self[Type].select{|t|t.respond_to? :uri}.map(&:uri) end
    def a type; types.member? type end
    def to_json *a; {'uri' => uri}.to_json *a end

    class Format < RDF::Format
      content_type     'application/json+rdf', :extension => :e
      content_encoding 'utf-8'
      reader { WebResource::JSON::Reader }
    end
    # native JSON format support in RDF-parser class
    class Reader < RDF::Reader
      format Format
      def initialize(input = $stdin, options = {}, &block)
        @graph = ::JSON.parse (input.respond_to?(:read) ? input : StringIO.new(input.to_s)).read
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
        @graph.map{|s,r|
          r.map{|p,o|
            o.justArray.map{|o|
              fn.call RDF::Statement.new(@base.join(s), RDF::URI(p),
                                         o.class==Hash ? @base.join(o['uri']) : (l = RDF::Literal o
                                                                                 l.datatype=RDF.XMLLiteral if p == 'http://rdfs.org/sioc/ns#content'
                                                                                 l))} unless p=='uri'}}
      end
      def each_triple &block; each_statement{|s| block.call *s.to_triple} end
    end
  end

  include JSON

  module HTTP
    # optimization bypasses RDFlib abstraction-funcall overhead for straight JSON to in-memory Hash parse common-case
    def load set
      g = {}                 # JSON tree (nested Hash in-memory)
      graph = RDF::Graph.new # graph
      rdf,json = set.partition &:isRDF

      # load RDF
      rdf.map{|n|
        graph.load n.localPath, :base_uri => n}
      graph.each_triple{|s,p,o| # each triple
        s = s.to_s; p = p.to_s # subject, predicate
        o = [RDF::Node, RDF::URI, WebResource].member?(o.class) ? o.R : o.value # object
        g[s] ||= {'uri'=>s}
        g[s][p] ||= []
        g[s][p].push o unless g[s][p].member? o} # insert

      # load JSON
      json.map{|n|
        n.transcode.do{|transcode|
          ::JSON.parse(transcode.readFile).map{|s,re| # subject
            re.map{|p,o| # predicate object(s)
              o.justArray.map{|o| # each triple
                o = o.R if o.class==Hash
                g[s] ||= {'uri'=>s}
                g[s][p] ||= []
                g[s][p].push o unless g[s][p].member? o} unless p == 'uri' }}}} # insert
      g
    end
  end
end
