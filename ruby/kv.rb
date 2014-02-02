#watch __FILE__
class E

  def [] p; predicate p end
  def []= p,o; setFs p,o end

  def predicate p
    pp = predicatePath p
    
  end

  def setFs p, o, undo = false
    pp = predicatePath p
    if o.class == E # resource
      t = pp.a o.path
      if undo
        t.delete if t.e
      else
        unless t.e
          if o.f    # file
            o.ln t  # link to file
          elsif o.e  # non-file
            o.ln_s t # symlink
          else      # no target
            t.mk    # dirent
          end
        end
      end
    else # literal
      str = nil
      ext = nil
      if o.class == String
        str = o
        ext = '.txt'
      else
        str = o.to_json
        ext = '.json'
      end
      t = pp.as str.h + ext
      if undo
        t.delete if t.e
      else
        t.w str, !o.class == String unless t.e
      end
    end
  end

  def unsetFs p,o; setFS p,o,true end

end
