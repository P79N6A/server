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
      (s p).listPredicates
    else
      editFs E(p),(o.class == E ? o : E(p).literal(o)),v
    end
  end

  def []= p,o
    self[p,o]
  end

  def editFs p,o,newVal=nil
    d=(s p).s o # object
    if newVal # edit
      if d.e  # oldVal?
        d.deleteNode # remove
        indexEdit p,o,'' # unindex
      end
      self[p,newVal] unless newVal.empty? # add
    else
      unless d.e
        indexEdit p,o,nil # index add
        d.dir # create
      end
    end
    touch if e
  end

  def triplrFsStore
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
    s = u.to_s.size
    subtree.map{|n|n.uri[s..-1].unpath}
   end

  def literalBlob o
    u = literalBlobURI o
    u.w o,!o.class==String unless u.f
  end

end
