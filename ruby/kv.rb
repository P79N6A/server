#watch __FILE__
class E

  def []= p,o
    self[p,o]
  end

  def [] p,o=nil, v=nil
    if o # set
      editFs p,o,v
    else # get
      (concatURI p).properties
    end
  end

  def editFs p, o, oO=nil
    p = p.E
    o = p.literal o unless o.class == E
    t = (concatURI p).concatURI o
    if oO                # updated triple
      if t.e             # old triple exists?
        t.deleteNode     # remove triple
        indexEdit p,o,'' # unindex
      end
      self[p,oO] unless oO.empty? # add triple
    else
      unless t.e          # triple exists?
        indexEdit p,o,nil # index triple
        if o.f            # add triple
          o.ln t          # hard link
        elsif o.e
          o.ln_s t        # symbolic link
        else
          t.mk            # dir entry
        end
      end
    end
  end

  def triplrDoc &f
    docBase.glob('#*').map{|s| s.triplrResource &f}
  end

  def triplrResource
    properties.map{|p|self[p].map{|o| yield uri, p.uri, o}}
  end

  def deletePredicate p
    self[p].each{|o|self[p,o,'']}
  end

  def properties
    subtree.map &:ro
   end

end
