%w{K Rb N Y Es}.map &->_{require 'element/'+_}

class Hash
  def graph g
    g.merge!({uri=>self})
  end
  %w{cacheGraphFile graphFile q}.map{|m|alias_method m,:graph}
  def attr p;map{|_,r|r[p].do{|o|return o}}; nil end
  # triples :: tripleSource
  def triples; uri.do{|s|
      map{|p,o|
        o.class == Array ? o.each{|o| yield s,p,o} : yield(s,p,o) unless p=='uri'}}
  end
end

class E

  class << self
    def console; ARGV.clear; require 'irb'
      IRB.start
    end
  end

  # fromStream :: Graph -> tripleSource -> Graph
  def fromStream m,*i
    send(*i) do |s,p,o|
      m[s] ||= {'uri'=>s}
      m[s][p] ||= []
      m[s][p].push o
    end; m
  end

  # tripleStream transformer stack
  fn 'graph/|',->e,_,m{e.fromStream m, *_['|'].split(/,/)}

  def E.graphFromStream s
    fn 'graph/'+s.to_s,->e,_,m{e.fromStream m, s}    
  end

  # Graph -> [Predicate]
  def E.graphProperties g
    g.values.select{|v|v.respond_to? :keys}.map(&:keys).flatten.uniq
  end

  # placeholder to circumvent empty-graph 404
  fn 'graph/_',->d,_,m{ m[d.uri] = {} }

  # in :: tripleSource -> vfs 
  def in i,*a
    send(i,*a){|s,p,o|E(s)[p,o]}
  end

  # add :: tripleSource -> vfs exists || create
  def add i,*a
    e={}
    send(i,*a) do |s,p,o|; r=E(s)
      (e[s].nil? ? e[s]=r.e : e[s]) || r[p,o]
    end
  end

  # addJSON :: tripleSource -> JSON exists || create
  def addJSON i,g,p=[]
    fromStream({},i).map{|u,r| # stream -> graph
      (E u).do{|e| # resource
        e.jsonGraph.e || # exists?
        (puts "a #{e}"
         p.map{|p|r[p].do{|o|e.index p,o[0]}} # index properties
         e.jsonGraph.w({u => r},true) # write
         e.roonga g # index content
         )}}
    self
  end

  # to_h :: -> Hash
  def to_h
    {'uri'=>uri}
  end
  
  def tripleSourceMIME &b;mime.do{|mime|
    yield uri,E::Type,(E mime)
      (MIMEsource[mime]||
       MIMEsource[mime.split(/\//)[0]]).do{|s|
        send *s,&b }}
  end

  def jsonGraph
    ((path[-1]=='/' ? path[0..-2] : path)+'.e').E    
  end

  # cacheGraphFile :: Graph -> Graph
  def cacheGraphFile g={}
    # native JSON-parse is usually faster than pure-Ruby RDF-parsers and non-RDF triple-discoverers
    s = readlink.dirname.prepend('/E/graphF/').a "/#{base}.json" # name
    s.e && (!e || s.m > m) && g.merge!(s.r(true)) || # exists and up-to-date
      (i = graphFromFile
       s.w i, true
       g.merge! i)
  end

  # cacheGraph :: Graph -> Graph
  def cacheGraph g={}
#   @r[:graph] ||= {} # doc->graph memoize 
   s = dirname.prepend('/E/graph/').a "/#{base}.json" # name
    s.e && (!e || s.m > m) && g.merge!(s.r(true)) || # exists and up-to-date
      (i = graph
       s.w i, true
       g.merge! i)
  end


  # graphFromFile :: URI -> Graph -> Graph
  # graph contained in explicitly-referenced file
  def graphFromFile g={}
   [ :tripleSourceNode, # filesystem data
     :tripleSourceMIME].# format-specific tripleStream
      each{|i| fromStream g,i } # tripleStream -> Graph
    g
  end

  # graph :: URI -> Graph -> Graph
  def graph g={}
    g.merge! ((jsonGraph.r true)||{}) # JSON source
    docs.map{|d| d.graphFromFile g }  # tripleStream sources
    g
  end

  # memoGraph :: Graph
  def memoGraph
    @graph ||= cacheGraph
  end

  # memoGraphFile :: Graph
  def memoGraphFile
    @graphFile ||= cacheGraphFile
  end

  # render :: MIME, Graph, env -> String
  def render mime,  d,e
   E[Render+mime].y d,e
  end

  def serialize mime
    E[Render+mime].y graph
  end

end
