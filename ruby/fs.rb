#watch __FILE__
class E

  def [] p; predicate p end
  def []= p,o
    if o
      setFs p,o
    else
      (predicate p).map{|o|
        unsetFs p,o}
    end
  end

  def predicate p, short = true
    p = predicatePath p, short
    p.take.map{|o|
      if o.f # literal
        case o.ext
        when "json"
          o.r true
        else
          o.r
        end
      else # resource
       E[o.uri.unpath p.uri.size]
      end}
  end

  def setFs p, o, undo = false, short = true
    p = predicatePath p, short # s+p URI
    t,v = p.objectPath o # triple URI
    puts "#{undo ? :un : ''}setFS #{t}"
    if o.class == E # resource
      if undo
        t.delete if t.e # undo
      else
        unless t.e
          if o.f    # file
            o.ln t  # link to file
          elsif o.e  # non-file
            o.ln_s t # symlink
          else      # target 404
            t.mk    # dirent
          end
        end
      end
    else # literal
      if undo
        t.delete if t.e  # remove 
      else
        t.w v unless t.e # write
      end
    end
  end

  def unsetFs p,o; setFs p,o,true end

  def triplrInode
    if d?
      yield uri, Posix+'dir#parent', parent
      c.map{|c| yield uri, Posix + 'dir#child', E[c.uri.gsub('?','%3F').gsub('#','23')]}
    end
    node.stat.do{|s|[:size,:ftype,:mtime].map{|p| yield uri, Stat+p.to_s, (s.send p)}}
  end
  
  def triplrSymlink
    realpath.do{|t|
      target = t.to_s.index(FSbase)==0 ? t.E : t.to_s
      yield uri, '/linkTarget', target }
  end

  def ln t, y=:link
    t = t.E # cast bare URI/string to resource
    if !t.e # destination exist?
      t.dirname.mk
      FileUtils.send y, node, t.node
    end
  end

  def ln_s t; ln t, :symlink end

  def r p=false
    if f
      p ? (JSON.parse readFile) : readFile
    else
      nil
    end
  rescue Exception => e
    puts e
  end

  def w o,s=false
    dirname.mk
    writeFile (s ? o.to_json : o)
    self
  end

end

class Pathname

  def E; to_s.force_encoding('UTF-8').unpath end

  def c
    return [] unless directory?
    children.delete_if{|n| n.basename.to_s.match /^\./}
    rescue
      []
  end
  
  def deleteNode
    FileUtils.send (file?||symlink?) ? :rm : :rmdir, self
    parent.deleteNode if parent.c.empty?
  end

end
