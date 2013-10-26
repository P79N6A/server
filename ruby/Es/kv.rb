watch __FILE__
class E

  def []= p,o
    self[p,o]
  end

  def [] p,o=nil, v=nil
    if o
      # bare predicateURI to resource
      p = p.E
      # literal to literalURI
      o = p.literal o unless o.class == E
      editFs p,o,v
    else
      concatURI(p).listPredicates
    end
  end

  def editFs p, o, newVal=nil
    puts "editFS #{uri} #{p} #{o}"
    t = (concatURI p).concatURI o
    if newVal # update
      if t.e  # oldVal?
        t.deleteNode # remove triple
        indexEdit p,o,'' # unindex
      end
      self[p,newVal] unless newVal.empty? # add triple
    else
      unless t.e
        indexEdit p,o,nil # index triple
        t.mk              # make triple
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

  def listPredicates
    subtree.map &:ro
   end

end
