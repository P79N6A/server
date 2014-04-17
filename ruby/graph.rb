#watch __FILE__
class R

  def fromStream m,*i
    send(*i) do |s,p,o|
      m[s] = {'uri' => s} unless m[s].class == Hash 
      m[s][p] ||= []
      m[s][p].push o unless m[s][p].class != Array || m[s][p].member?(o)
    end; m
  end

  def graph graph = {}
    fileResources.map{|d|
      d.fileToGraph graph}
    graph
  end

  def fileToGraph graph = {}
    return graph unless e
    graph.mergeGraph rdfDoc.r true
  end


  module JSONGraph

    class Format < RDF::Format
      content_type     'application/json+rdf', :extension => :e
      content_encoding 'utf-8'
      reader { R::JSONGraph::Reader }
    end

    class Reader < RDF::Reader
      format Format

      def initialize(input = $stdin, options = {}, &block)
        @graph = JSON.parse (input.respond_to?(:read) ? input : StringIO.new(input.to_s)).read
        @host = options[:host] || 'localhost'
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
          fn.call RDF::Statement.new(s.R.hostURL(@host), p.R,
                                     o.class == Hash ? o.R.hostURL(@host) :
                                     (l = RDF::Literal o
                                      l.datatype=RDF.XMLLiteral if p == Content
                                      l))}
      end

      def each_triple &block
        each_statement{|s| block.call *s.to_triple}
      end

    end

  end


  def rdfDoc # pointer to RDF representation of fs-item, or itself if RDF
    doc = self
    unless %w{e jsonld n3 nt owl rdf ttl}.member? ext # already RDF!
      doc = R '/cache/RDF/' + uri.h.dive + '.e'
      unless doc.e && doc.m > m # up-to-date?
        g = {} # doc-graph
        [:triplrMIME,:triplrInode].map{|t| fromStream g, t} # triplize
        doc.w g, true # update
        puts "updating #{doc}"
      else
        puts "up-to-date #{doc}"
      end
    end
    doc
  end

  # GET Resource -> local RDF cache
  # JSON + Hash (.e)
  def addDocsJSON triplr, host, p=nil, hook=nil, &b
    graph = fromStream({},triplr)
    docs = {}
    graph.map{|u,r|
      e = u.R                 # resource
      doc = e.jsonDoc         # doc
      doc.e ||                # exists - we're nondestructive here
      (docs[doc.uri] ||= {}   # init doc-graph
       docs[doc.uri][u] = r   # add to graph
       p && p.map{|p|         # index predicate
         r[p].do{|v|v.map{|o| # values exist?
             e.index p,o}}})} # index triple
    docs.map{|d,g|            # resources in docs
      d = d.R; puts "<#{d.docroot}>"
      d.w g,true              # write
      hook[d,g,host] if hook} # insert-hook
    graph.triples &b if b     # emit triples
    self
  end

  # GET Resource -> local RDF cache
  # RDF::Repository (.n3)
  def addDocsRDF options = {}
    g = RDF::Repository.load self, options
    g.each_graph.map{|graph|
      if graph.named?
        doc = graph.name.n3
        unless doc.e
          doc.dirname.mk
          RDF::Writer.open(doc.d){|f|f << graph} ; puts "<#{doc.docroot}> #{graph.count} triples"
          options[:hook][doc,graph,options[:hostname]] if options[:hook]
        end
      end}
    g
  end

  def jsonDoc; docroot.a '.e' end

  def triplrJSON
    yield uri, '/application/json', r(true) if e
  rescue Exception => e
    puts "triplrJSON #{e}"
  end

  def to_json *a
    {'uri' => uri}.to_json *a
  end

  Render['application/json'] = -> d, _ = nil { d.to_json }

end

class Hash

  def except *ks
    clone.do{|h|
      ks.map{|k|h.delete k}
      h}
  end

  def graph g
    g.merge!({uri=>self})
  end

  def mergeGraph g
    g.triples{|s,p,o|
      self[s] = {'uri' => s} unless self[s].class == Hash 
      self[s][p] ||= []
      self[s][p].push o unless self[s][p].member? o } if g
    self
  end

  def triples &f
    map{|s,r|
      r.map{|p,o|
        o.justArray.map{|o|yield s,p,o} unless p=='uri'} if r.class == Hash}
  end

  def resourcesOfType type
    values.select{|resource|
      resource[R::Type].do{|types|
        types.justArray.map(&:maybeURI).member? type }}
  end

end
