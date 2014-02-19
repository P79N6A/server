#watch __FILE__
class R
=begin
  a RDF::URI has a path defined in names.rb, so do other concepts like a full "triple" - here we've built a RDF store using them
  since this results in one path per-triple, it's mainly used for current resource-state and "backlink" (reverse order) indexing

  TODO expose this as RDF::Repository
=end

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
    p.node.take.map{|n|
      if n.file? # literal
        o = n.R
        case o.ext
        when "json"
          o.r true
        else
          o.r
        end
      else # resource
       R[n.to_s.unpath p.d.size]
      end}
  end

  def setFs p, o, undo = false, short = true
    p = predicatePath p, short # s+p URI
    t,literal = p.objectPath o # s+p+o URI
    puts "#{undo ? :- : :+} <#{t}>"
    if o.class == R # resource
      if undo
        t.delete if t.e # undo
      else
        unless t.e
          if o.f    # file?
            o.ln t  # link
          else
            t.mk    # dirent
          end
        end
      end
    else # literal
      if undo
        t.delete if t.e  # remove 
      else
        t.w literal unless t.e # write
      end
    end
  end

  def unsetFs p,o; setFs p,o,true end

  def triplrInode
    if d?
      yield uri, Posix+'dir#parent', parent
      c.map{|c| yield uri, Posix + 'dir#child', R[c.uri.gsub('?','%3F').gsub('#','23')]}
    end
    node.stat.do{|s|[:size,:ftype,:mtime].map{|p| yield uri, Stat+p.to_s, (s.send p)}}
  end
  
  def triplrSymlink
    realpath.do{|t|
      target = t.to_s.index(FSbase)==0 ? t.R : t.to_s
      yield uri, '/linkTarget', target }
  end

  def ln t, y=:link
    t = t.R
    t = t.uri[0..-2].R if t.uri[-1] == '/'
    if !t.e
      t.dirname.mk
      FileUtils.send y, node, t.node
    end
  end

  def delete;   node.deleteNode if e; self end
  def exist?;   node.exist? end
  def file?;    node.file? end
  def ln_s t; ln t, :symlink end
  def mk;       e || FileUtils.mkdir_p(d); self end
  def mtime;    node.stat.mtime if e end
  def touch;    FileUtils.touch node; self end

  def read p=false
    if f
      p ? (JSON.parse File.open(d).read) : File.open(d).read
    else
      nil
    end
  rescue Exception => e
    puts e
  end

  def write o,s=false
    dirname.mk
    File.open(d,'w'){|f|
      f << (s ? o.to_json : o)}
    self
  end

  alias_method :e, :exist?
  alias_method :f, :file?
  alias_method :m, :mtime
  alias_method :r, :read
  alias_method :w, :write

end

class Pathname

  def R; to_s.force_encoding('UTF-8').unpath end

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
