#watch __FILE__
class R
=begin
 Hash
  {subject => {predicate => object}}

 types:
  subject: String
  predicate: String
  object:
   Array: each member becomes a triple
    [objectA, objectB..]

   URIs:
   RDF::URI
   R (our resource-class)
   Hash with 'uri' key

  literals:
   RDF::Literal
   String
   Integer
   FLoat

=end

  # triples -> graph
  def fromStream m,*i
    send(*i) do |s,p,o|
      m[s] = {'uri' => s} unless m[s].class == Hash 
      m[s][p] ||= []
      m[s][p].push o unless m[s][p].class != Array || m[s][p].member?(o)
    end
    m
  end

  # inode -> inode (Non-RDF -> RDF)
  def justRDF pass = RDFsuffixes
    if pass.member? realpath.do{|p|p.extname.tail} # already desired MIME
      self
    else
      doc = R['/cache/RDF/'+R.dive(uri.h)+'.e'].setEnv @r # cache URI
      doc.w fromStream({},:triplrMIME),true unless doc.e && doc.m > m # cache
      doc
    end
  end

  # inode -> graph
  def nodeToGraph graph
    base = @r.R.join(stripDoc) if @r
    justRDF(%w{e}).do{|f| # just native JSON
      if @r && @r[:container] && file? # fs-meta
        native = f == self
        s = native ? stripDoc.uri : uri # generic-resource or file
        s = base.join(s).to_s if base
        graph[s] ||= {'uri' => s}
        [Type,Size,Mtime].map{|p|graph[s][p] ||= []} # init fields
        graph[s][Size].push f.size
        graph[s][Mtime].push f.mtime.to_i
        graph[s][Type].push R[native ? Resource : (Stat + 'File')]
      end
      (f.r(true)||{}).triples{|s,p,o| # triples
        if base
          s = base.join(s).to_s     # bind subject-URI
          if o.class==Hash && o.uri # bind object-URI
            o['uri'] = base.join(o.uri).to_s
          end
        end
        graph[s] ||= {'uri' => s}
        graph[s][p] ||= []
        graph[s][p].push o #unless graph[s][p].member? o
      }}
    graph
  end
  
  # URI -> graph
  def graph graph = {}
    fileResources.map{|d|d.nodeToGraph graph}
    graph
  end

  # triples -> fs-store
  def triplrStoreJSON triplr, host = 'localhost',  p = nil,  hook = nil, &b
    graph = fromStream({},triplr) # collect triples
    R.store graph, host, p, hook  # cache
    graph.triples &b if b         # emit triples
    self
  end

  # graph -> fs-store
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

  # URI -> fs-store
  def store options = {}
    g = RDF::Repository.load self, options
    g.each_graph.map{|graph|
      if graph.named?
        doc = graph.name.n3
        unless doc.e
          doc.dir.mk
          file = doc.pathPOSIX
          RDF::Writer.open(file){|f|f << graph} ; puts "<#{doc.docroot}> #{graph.count} triples"
          options[:hook][doc,graph,options[:hostname]] if options[:hook]
        end
      end}
    g
  end
 
end

class Array
  def sortRDF env
    sort = (env.q['sort']||'dc:date').expand
    sortType = [R::Size, R::Stat+'mtime'].member?(sort) ? :to_i : :to_s
    sort_by{|i|
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
