class E
=begin
   a simple key/value RDF store on the filesystem

  get
   E['http://www.kanzaki.com/ns/music#EnglishHorn'][RDFs+'comment']
   -> ["A double-reed woodwind instrument, larger member of the oboe family."]
  
  set
   (E'lement')['level']='trace'
  
  update
   E['lement']['level','trace','abundant']
  
  delete
   E('lement')['level','abundant','']
  
=end


  def []= p,o
    self[p,o]
  end

  def [] p,o=nil, v=nil
    if o
      # cast bare URI to resource
      p = E p
      # cast literals to URI
      o = p.literal o unless o.class == E
      editFs p,o,v
    else
      concatURI(p).listPredicates
    end
  end

  def editFs p,o,newVal=nil

    # triple
    t = concatURI(p).concatURI(o)

    if newVal # update
      if t.e  # oldVal?
        t.deleteNode # remove triple
        indexEdit p,o,'' # unindex
      end
      self[p,newVal] unless newVal.empty? # add triple
    else
      unless t.e
        indexEdit p,o,nil # index triple
        t.dir # add triple
      end
    end
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
    subtree.map &:ro
   end

  def literalBlob o
    u = literalBlobURI o
    u.w o,!o.class==String unless u.f
  end

end
