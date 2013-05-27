class E

  # a simple key/value RDF store on a fs

  # accessor
  # E[W3+'People/Berners-Lee/card'][CC+'license']
  # -> #<E:0x2ab4ecc65ae0 @uri="http://creativecommons.org/licenses/by-nc/3.0/">
  def i p
    e=self[p]; e ? e[0] : e
  end

  # *get*
  # (E'http://www.kanzaki.com/ns/music#EnglishHorn')[RDFs+'comment']
  # -> ["A double-reed woodwind instrument, larger member of the oboe family."]
  #
  # *set*
  # (E'lement')['level']='trace'
  #
  # *update*
  # (E'lement')['level','trace','abundant']
  #  
  def [] p,o=nil, v=nil
    unless o
      g p
    else
      edit E(p),(o.class == E ? o : E(p).li(o)),v
    end
  end

  def []= p,o
    self[p,o]
  end

  # get property
  # (E W3+'People/Berners-Lee/card').g Type
  # -> [#<E:0x2ab4eccc41d0 @uri="http://xmlns.com/foaf/0.1/PersonalProfileDocument">]
  def g p
    (s p).lp
  end 

  def attr p
    memoGraph.do{|m|
      m.map{|u,r|
        r[p].do{|o|return o}}}
    nil
  end

  def edit p,o,v=nil
    d=(s p).s o # object
    if v # edit
      if d.e
        d.de # remove
        ix p,o,'' # unindex
      end
      self[p,v] unless v.empty? # add
    else
      unless d.e
        ix p,o,nil # index
        d.dir # create
      end
    end
    touch if e
  end

  # fs :: vfs -> tripleSource
  def fs
    lp.map{|p|self[p].map{|o|yield uri,p.uri,o}}
  end

  # delete property/predicate
  def dp p
    self[p].each{|o| self[p,o,'']}
  end

  # property list
  # E -> [E]
  def lp
    s = u.to_s.size+1
    subtree.map{|n|n.uri[s..-1].unpath}.- [nil]
   end

  # write blob
  def liB o
    liBU(o).wi(o,!o.class==String)
  end

  def index p,o
    ix E(p),(o.class == E ? o : E(p).li(o)),nil
  end

  def ix p,o,a
    return if @n
    p.pIndex.n[o,self,a]
  end

  # stop auto-index of statements on this resource pointer
  # ( index is a normal resource )
  def n
    @n = 1
    self
  end

  def rangeP n=8,d=:desc,s=nil
    pIndex.subtree(n,d,s).map &:ro
  end

  def rangePO o,n=8,d=:desc,s=nil
    poIndex(o).subtree(n,d,s).map &:ro
  end

  def po o
    pIndex[o.class == E ? o : li(o)]
  end

  def pIndex
    '/index'.E.s self
  end

  def poIndex o
    pIndex.s o
  end

end
