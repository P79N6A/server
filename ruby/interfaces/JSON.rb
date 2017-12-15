class R

  module JSON

    class Format < RDF::Format
      content_type     'application/json+rdf', :extension => :e
      content_encoding 'utf-8'
      reader { R::JSON::Reader }
    end

    # JSON -> RDF
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

  # URI -> JSON
  def to_json *a; {'uri' => uri}.to_json *a end # R -> Hash

end
