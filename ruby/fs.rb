#watch __FILE__
class R

  def triplrDoc &f; stripDoc.glob('#*').map{|s| s.triplrResource &f} end
  def triplrResource; predicates.map{|p| self[p].map{|o| yield uri, p.uri, o}} end

  def [] p; predicate p end
  def []= p,o
    if o
      setFs p,o
    else
      (predicate p).map{|o|
        unsetFs p,o}
    end
  end

  def predicatePath p, s = true
    container.as s ? p.R.shorten : p
  end

  def predicates
    container.c.map{|c|c.base.expand.R}
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

  def unsetFs p,o
    setFs p,o,true
  end

  def triplrInode
    if node.directory?
      yield uri, Posix+'dir#parent', parent
      yield uri, Type, R[LDP+'Container']
      yield uri, Type, R[Stat+'Directory']
      c.map{|c|
        yield uri, LDP+'contains', R[c.uri.gsub('?','%3F').gsub('#','23')]}
    end
    node.stat.do{|s|[:size,:ftype,:mtime].map{|p| yield uri, Stat+p.to_s, (s.send p)}}
  end
  
  def triplrSymlink
    realpath.do{|t|
      target = t.to_s.index(FSbase)==0 ? t.R : t.to_s
      yield uri, '/linkTarget', target }
  end

  def triplrStdOut e,f='/',g=/^\s*(.*?)\s*$/,a=sh
    `#{e} #{a}|grep :`.each_line{|i|
      i = i.split /:/
    yield uri, (f + (i[0].match(g)||[0,i[0]])[1].       # s
     gsub(/\s/,'_').gsub(/\//,'-').gsub(/[\(\)]+/,'')), # p
      i.tail.join(':').strip.do{|v|v.match(/^[0-9\.]+$/) ? v.to_f : v}} # o
#  rescue
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
  def mtime;    node.stat.mtime if e end
  def touch;    FileUtils.touch node; self end

  def mk
    e || FileUtils.mkdir_p(d)
    self
  rescue Exception => x
    puts x
    self
  end

  def read p=false
    if f
      p ? (JSON.parse File.open(d).read) : File.open(d).read
    else
      nil
    end
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
