%w{K Rb N Y Es}.map &->_{require 'element/'+_}

class Hash
  def graph g
    g.merge!({uri=>self})
  end
  %w{cacheGraph graphFrag q}.map{|m|alias_method m,:graph}
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

  fn 'graph/|',->e,_,m{e.fromStream m, *_['|'].split(/,/)}

  def E.graphFromStream s
    fn 'graph/'+s.to_s,->e,_,m{e.fromStream m, s}    
  end

  # Graph -> [Predicate]
  def E.graphProperties g
    g.values.select{|v|v.respond_to? :keys}.map(&:keys).flatten.uniq
  end

  fn 'graph/_',->d,_,m{m[d.uri]={}} # graph stub
  # used eg for Exhibit view, it requests graph later but we don't want 404!

  # resource :: tripleSource -> jsonResource
  def resource i,*a
    r={}
    send(i,*a) do |s,p,o|
      r['uri'] ||= s
      r[p] ||= []
      r[p].push o
    end
    r
  end

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
        e.em.e || # exists?
        (puts " a #{e}" # add
         p.map{|p|r[p].do{|o|e.index p,o[0]}} # index properties
         e.em.w({u => r},true) # write
         e.roonga g # index content
         )}}
    self
  end

  # to_h :: -> Hash
  def to_h
    {'uri'=>uri}
  end

  # graph :: Graph -> Graph
  def graph g={}
   [ :tripleSourceNode, # filesystem data
     :tripleSourceMIME, # domain-specific metadata
   ].each{|i| fromStream g,i}  # tripleStream -> Graph
    g.merge! ((em.r true)||{}) # JSON graph-storage
    g
  end
  
  def tripleSourceMIME &b;mime.do{|mime|
    yield uri,E::Type,(E mime)
      (MIMEsource[mime]||
       MIMEsource[mime.split(/\//)[0]]).do{|s|
        send *s,&b }}
  end

  def em
    @em ||= ((path[-1]=='/' ? path[0..-2] : path)+'.e').E    
  end

  # cacheGraph :: Graph -> Graph
  def cacheGraph g={}
    s = readlink.dirname.prepend('/E/resource/').a "/#{base}.json"
    s.e && (!e || s.m > m) && g.merge!(s.r(true)) ||
      (i = graph
       s.w i, true
       g.merge! i)
  end
  
  def q g={}
    F['graph/'+@r.q['graph']].do{|y|y.(self,@r.q,g)} || (cacheGraph g)
  end

  def graphFrag g={};@r[:graph]||={}
    docs.map{|d|
      (@r[:graph][d.uri] ||= d.cacheGraph).do{|m|
        m[uri].do{|r|
          g.merge!({uri => r})}}}
    g end

  # memoGraph :: Graph
  def memoGraph
    @graph ||= cacheGraph
  end

  # render :: MIME, Graph, env -> String
  def render mime,  d,e
   E[Render+mime].y d,e
  end

  def serialize mime
    E[Render+mime].y graph
  end

end
