#watch __FILE__

%w{date digest/sha1 fileutils json open-uri pathname}.each{|r|require(r)}

class E

  def d
    node.to_s
  end

  def node
    Pathname.new FSbase + path
  end
  alias_method :no, :node

  def inside
    node.expand_path.to_s.index(FSbase) == 0
  end

  def siblings
    parent.c
  end

  def children
    node.c.map &:E
  end
  alias_method :c, :children


  # node exists?
  def exist?
    node.exist?
  end
  alias_method :e, :exist?

  # directory?
  def d?
    node.directory?
  end

  # file?
  def file?
    node.file?
  end
  alias_method :f, :file?

  # modification time
  def mtime
    node.stat.mtime if e
  end
  alias_method :m, :mtime

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
  
  def realpath
    node.realpath
  rescue Errno::ENOENT
    nil
  end

  def mk
    e || FileUtils.mkdir_p(d)
    self
  end

  # create link
  def ln t
    t = t.E # cast bare URI/string to resource
    if !t.e # destination exist?
      t.dirname.mk
      FileUtils.link node, t.node
    end
  end

  # create symlink
  def ln_s t
    t = t.E # cast bare URI/string to resource
    if !t.e # destination exist?
      t.dirname.mk
      FileUtils.symlink node, t.node
    end
  end

  def touch
    FileUtils.touch node
    self
  end
    
  def deleteNode
    node.deleteNode if e
    self
  end

  def size
    node.size
  end

  def read
    f ? r : get
  end

  def get
    (open uri).read
  end

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

  def writeFile c
    File.open(d,'w'){|f|f << c}
  end

  def readFile
    File.open(d).read
  end

end

class Pathname

  def E
    to_s.force_encoding('UTF-8').unpathFs
  end

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

class File::Stat
  def utime
    mtime.to_i
  end
end
