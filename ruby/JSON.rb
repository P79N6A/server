#watch __FILE__
class R

  module Format # Reader class for JSON format

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

  def triplrJSON
    if e
      yield uri+'#', Type, R[MIMEtype + 'application/json']
      yield uri+'#', Content, r(true)
    end
  rescue Exception => e
    puts e
  end

  def to_json *a
    {'uri' => uri}.to_json *a
  end

  ViewA[MIMEtype+'application/json'] = ->v,e{
    [v[Content].justArray.map(&:html), H.once(e,'base',H.css('/css/html',true))]}

  Render['application/json'] = -> d,e {
    JSONview[e.q['view']].do{|f|
      f[d,e]
    } ||
    d.to_json }

end
