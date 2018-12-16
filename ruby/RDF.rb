class Hash
  def R # cast to WebResource
    WebResource.new(uri).data self
  end
  # URI accessor
  def uri; self["uri"] end
end
class WebResource
  module JSON
    include URIs
    def [] p; (@data||{})[p].justArray end
    def data d={}; @data = (@data||{}).merge(d); self end
    def types; @types ||= self[Type].select{|t|t.respond_to? :uri}.map(&:uri) end
    def a type; types.member? type end
    def to_json *a; {'uri' => uri}.to_json *a end

    class Format < RDF::Format
      content_type     'application/json+rdf', :extension => :e
      content_encoding 'utf-8'
      reader { WebResource::JSON::Reader }
    end
    # RDF parser for JSON format
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
  module MIME
    # file -> bool
    def isRDF
      if %w{atom n3 owl rdf ttl}.member? ext
        return true
      elsif feedMIME?
        return true
      end
      false
    end

    # file -> file
    def toRDF
      isRDF ? self : rdfize
    end

    # file -> file
    def rdfize
      return self if ext == 'e'
      hash = node.stat.ino.to_s.sha2
      doc = R['/cache/RDF/'+hash[0..2]+'/'+hash[3..-1]+'.e']
      unless doc.e && doc.m > m
        tree = {}
        triplr = Triplr[mime]
        unless triplr
          puts "#{uri}: triplr for #{mime} missing"
          triplr = :triplrFile
        end
        send(*triplr){|s,p,o|
          tree[s] ||= {'uri' => s}
          tree[s][p] ||= []
          tree[s][p].push o}
        doc.writeFile tree.to_json
      end
      doc
    end
  end
  module HTTP
    # load JSON and RDF to URI-indexed Hash. HTML and Feed renderers take this as input
    def load set # file-set argument
      g = {}                 # JSON tree
      graph = RDF::Graph.new # RDF graph
      rdf,non_rdf = set.partition &:isRDF
#      puts "RDF: #{rdf.join ' '} nonRDF: #{non_rdf.join ' '}"
      # load RDF
      rdf.map{|n|
        opts = {:base_uri => n}
        opts[:format] = :feed if n.feedMIME?
        graph.load n.localPath, opts
      }
      graph.each_triple{|s,p,o| # each triple
        s = s.to_s; p = p.to_s # subject, predicate
        o = [RDF::Node, RDF::URI, WebResource].member?(o.class) ? o.R : o.value # object
        g[s] ||= {'uri'=>s}
        g[s][p] ||= []
        g[s][p].push o unless g[s][p].member? o} # insert

      # load non-RDF
      non_rdf.map{|n|
        n.rdfize.do{|transcode|
          ::JSON.parse(transcode.readFile).map{|s,re| # subject
            re.map{|p,o| # predicate object(s)
              o.justArray.map{|o| # each triple
                o = o.R if o.class==Hash
                g[s] ||= {'uri'=>s}
                g[s][p] ||= []
                g[s][p].push o unless g[s][p].member? o} unless p == 'uri' }}}} # insert

      g # graph reference returned to caller
    end
  end
  module Webize
    # index resources on timeline
    def indexRDF options = {}
      newResources = []
      # load resource
      g = RDF::Repository.load self, options

      # visit named-graph resources
      g.each_graph.map{|graph|

        # find timestamp for timeline-linkage
        graph.query(RDF::Query::Pattern.new(:s,R[R::Date],:o)).first_value.do{|t|

          # mint document-URI
          time = t.gsub(/[-T]/,'/').sub(':','/').sub /(.00.00|Z)$/, ''
          slug = (graph.name.to_s.sub(/https?:\/\//,'.').gsub(/[\W_]/,'..').sub(/\d{12,}/,'')+'.').gsub(/\.+/,'.')[0..127].sub(/\.$/,'')
          doc =  R["/#{time}#{slug}.ttl"]

          unless doc.e # TODO oldversion-archival for updates happening without a URI change
            doc.dir.mkdir
            resource = doc.stripDoc
            graph << RDF::Statement.new(graph.name, R[Cache], resource)
            RDF::Writer.open(doc.localPath){|f|f << graph}
            puts  "\e[7mhttp://localhost" + resource +  "\e[0m"
            newResources << doc
          end
          true}}

      newResources
    rescue Exception => e
      puts uri, e.class, e.message
    end

  end
end
