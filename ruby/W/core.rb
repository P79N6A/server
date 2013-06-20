%w{K Rb N Y Es}.map &->_{require 'element/'+_}

class Hash
  def graph g
    g.merge!({uri=>self})
  end
  %w{graphFromFile q}.map{|m|alias_method m,:graph}
  def attr p;map{|_,r|r[p].do{|o|return o}}; nil end
  # Hash -> tripleStream
  def triples; uri.do{|s|
      map{|p,o|
        o.class == Array ? o.each{|o| yield s,p,o} : yield(s,p,o) unless p=='uri'}}
  end
end

class E

  # fromStream :: Graph -> tripleStream -> Graph
  def fromStream m,*i
    send(*i) do |s,p,o|
      m[s] = {'uri' => s} unless m[s].class == Hash 
      m[s][p] ||= []
      m[s][p].push o
    end; m
  end

  # tripleStream transformer stack
  fn 'graph/|',->e,_,m{e.fromStream m, *_['|'].split(/,/)}

  def E.graphFromStream s
    fn 'graph/'+s.to_s,->e,_,m{e.fromStream m, s}    
  end

  # placeholder to circumvent empty-graph 404
  fn 'graph/_',->d,_,m{ m[d.uri] = {} }

  # to_h :: -> Hash
  def to_h
    {'uri'=>uri}
  end
  
  def triplrMIMEdispatch &b;mime.do{|mime|
    yield uri,E::Type,(E mime)
      (MIMEsource[mime]||
       MIMEsource[mime.split(/\//)[0]]).do{|s|
        send *s,&b }}
  end

  def graphFromFile g={}
    g.merge! r(true) if ext=='e' # native JSON -> graph
    [:triplrInode,        # filesystem data
     :triplrMIMEdispatch].# format-specific tripleStream
      each{|i| fromStream g,i } # tripleStream -> Graph
    g
  end

  def graph g={}
    docs.map{|d|d.graphFromFile g}  # tripleStream -> graph
    g
  end

  # render :: MIME, Graph, env -> String
  def render mime, d, e
   E[Render+mime].y d,e
  end

end
