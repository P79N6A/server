#watch __FILE__
class E

  def [] p; predicate p end

  def predicate p
    pp = predicatePath p
    
  end

  def predicates
    container.c.map{|c|c.base.expand.E}
  end

  def []= p,o
    setFs p,o
  end

  def unsetFs p,o; setFS p,o,true end
  def setFs p, o, undo = false
    pp = predicatePath p
    if o.class == E # resource
      t = pp.a o.path
      if undo
        
      else
        unless t.e
          if o.f # file
            o.ln t  # link
          elsif o.e  # exists
            o.ln_s t  # symbolic link
          else
            t.mk     # dirent
          end
        end
      end
    else # literal value

    end
    t = (concatURI p).concatURI o
    if oO             # updated triple
      if t.e          # old triple exists?
        t.delete      # remove triple
        index_ p,o,'' # unindex
      end             # add
      self[p,oO] unless oO.class==String && oO.empty? # 2nd arg is new val - skip empty-val / nil
    else
      unless t.e       # triple exists?
        index_ p,o,nil # index triple

      end
    end
  end

  def literal o
    return o if o.class == E
    u = (if o.class == String
           E "/E/blob/"+o.h.dive
         else
           E "/E/json/"+[o].to_json.h.dive
         end)
    u.w o, !o.class == String unless u.f
    u
  end

  def triplrDoc &f
    docBase.glob('#*').map{|s| s.triplrResource &f}
  end

  def triplrResource
    predicates.map{|p|self[p].map{|o| yield uri, p.uri, o}}
  end

end
