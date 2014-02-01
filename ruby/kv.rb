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
    if oO              # updated triple
      if t.e           # old triple exists?
        t.deleteNode   # remove triple
        index_ p,o,''  # unindex
      end              # add
      self[p,oO] unless oO.class==String && oO.empty? # 3rd arg means new val - empty-val -> nil
    else
      unless t.e       # triple exists?
        index_ p,o,nil # index triple
        if o.f         # add triple
          o.ln t       # hard link
        elsif o.e
          o.ln_s t     # symbolic link
        else
          t.mk         # dir entry
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
    meta.c.map{|c|c.base.expand.E}
  end

end
