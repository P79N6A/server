class R
#  graph in JSON:
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

  def pack # consolidate native docs in a dir to a single file
    return unless directory?
    res = (child '*.e').glob
    return unless res.size > 1
    graph = {}
    res.map{|r|
      r.nodeToGraph graph
      r.delete}
    child('index.e').w graph, true
    self
  end

  # copy triples in stream to local store
  def triplrWrite triplr, &b
    graph = fromStream({},triplr) # stream triples into Hash-graph
    docs = {}
    rel = SIOC+'reply_of'
    graph.map{|u,r| # each resource
     (e = u.R          # resource URI
      doc = e.jsonDoc     # doc URI
      doc.e ||               # cache hit ||
      (docs[doc.uri] ||= {}     # init doc graph
       docs[doc.uri][u] = r        # resource to doc-graph
       r[rel].do{|v|v.map{|o|         # objects exist?
                 e.index rel,o}})) if u} # index property
    docs.map{|d,g| # each doc
      doc = d.R
      doc.w g, true # write doc
      indexDate = !doc.path.tail.match?(/^(address|\d{4})\//) # mail and date-dirs already on timeline
      g.map{|u,r| # inspect resources
        r[Date].do{|t| # date attribute
          t = t[0].to_s.gsub(/[-T]/,'/').sub(':','/').sub /(.00.00|Z)$/, '' # iso8601 to date-path, for timeline
          base = (u.sub(/https?:\/\//,'.').gsub(/\W/,'..').gsub(FeedStop,'').sub(/\d{12,}/,'')+'.').gsub /\.+/,'.' # clean name slug
          puts "< http://localhost/#{t}#{base[0..-2]}"
          doc.ln R["//localhost/#{t}#{base}e"]}} if indexDate # link to timeline
    }
    graph.triples &b if b # emit triples
    self
  end

  # copy remote resource to local store
  def store options = {}
    g = RDF::Repository.load self, options
    g.each_graph.map{|graph|
      if graph.named?
        doc = graph.name.ttl
        unless doc.e
          doc.dir.mk
          file = doc.pathPOSIX
          RDF::Writer.open(file){|f|f << graph}
          graph.query(RDF::Query::Pattern.new(:s,R[R::Date],:o)).first_value.do{|t| # query for timestamp
            time = t.gsub(/[-T]/,'/').sub(':','/').sub /(.00.00|Z)$/, '' # time to pathname
            base = (graph.name.to_s.sub(/https?:\/\//,'.').gsub(/\W/,'..').gsub(FeedStop,'').sub(/\d{12,}/,'')+'.').gsub /\.+/,'.'
            puts "< http://localhost/#{time}#{base[0..-2]}"
            doc.ln R["//localhost/#{time}#{base}ttl"]} # link to timeline
        end
      end}
    g
  rescue Exception => e
    puts uri, e.class, e.message #, e.backtrace[0..2]
    g
  end

  # native-JSON-format RDF interface
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

  # return just RDF files of whitelisted formats, transcode non-RDF as necessary
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
