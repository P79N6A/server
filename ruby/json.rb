class Hash

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

  # self -> tripleStream
  def triples &f
    map{|s,r|
      r.map{|p,o|
        o.class == Array ? o.each{|o| yield s,p,o} : yield(s,p,o) unless p=='uri'} if r.class == Hash
    }
  end

end

class E

  def triplrJSON
    yield uri, '/application/json', (JSON.parse read) if e
  rescue Exception => e
  end

  def to_json *a
    to_h.to_json *a
  end

  fn Render+'application/json',->d,_=nil{[d].to_json}

end
