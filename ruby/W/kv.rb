class E

  # a simple key/value RDF store on a fs

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
      (s p).lp
    else
      edit E(p),(o.class == E ? o : E(p).li(o)),v
    end
  end

  def []= p,o
    self[p,o]
  end

  def edit p,o,v=nil
    d=(s p).s o # object
    if v # edit
      if d.e
        d.deleteNode # remove
        indexEdit p,o,'' # unindex
      end
      self[p,v] unless v.empty? # add
    else
      unless d.e
        indexEdit p,o,nil # index add
        d.dir # create
      end
    end
    touch if e
  end

  # fs :: vfs -> tripleSource
  def fs
    listPredicates.map{|p|
      self[p].map{|o|
        yield uri, p.uri, o }}
  end

  def deletePredicate p
    self[p].each{|o| self[p,o,'']}
  end

  # property list
  # E -> [E]
  def listPredicates
    s = u.to_s.size+1
    subtree.map{|n|n.uri[s..-1].unpath}.- [nil]
   end

  def literalBlob o
    u = literalBlobURI o
    w o, !o.class==String unless u.f
  end

  # index :: predicateURI, object 
  def index p,o
    indexEdit E(p),                         # predicate -> resource
      (o.class == E ? o : E(p).literal(o)), # object -> resource
       nil
  end

  def indexEdit p,o,a
    return if @noIndex
    # add/remove properties of index-resource
    p.pIndex.noIndex[o,self,a]
  end

  # stop auto-index of statements on this resource
  # (index is a normal resource )
  def noIndex
    @noIndex = 1
    self
  end

  # range query on predicate index
  def rangeP n=8,d=:desc,s=nil
    pIndex.subtree(n,d,s).map &:ro
  end

  # range query on predicate-object index
  def rangePO o,n=8,d=:desc,s=nil
    poIndex(o).subtree(n,d,s).map &:ro
  end

  # subjects matching a predicate-object pair
  def po o
    pIndex[o.class == E ? o : literal(o)]
  end

  # predicate index
  def pIndex
    '/index'.E.s self
  end

  # predicate-object index
  def poIndex o
    pIndex.s o
  end

end
