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

  # glob :: pattern -> [E]
  def glob p=""
    (Pathname.glob d + p).map &:E
  end
  fn 'set/glob',->d,e,m{d.glob.concat d.pathSegment.glob}
  fn 'graph/glob',->d,e,m{
    (F['set/glob'][d,e,m]).map{|c|
      c.fromStream m, :triplrInode, false }}
  
  def parent
    E Pathname.new(uri).parent
  end

  def siblings
    parent.c
  end

  def children
    no.c.map &:E
  end
  alias_method :c, :children


  # node exists?
  def exist?
    no.exist?
  end
  alias_method :e, :exist?

  # directory?
  def d?
    no.directory?
  end

  # file?
  def file?
    no.file?
  end
  alias_method :f, :file?

  # modification time
  def mtime
    no.stat.mtime if e
  end
  alias_method :m, :mtime

  def triplrInode children=true
    e && (d? && (yield uri, Posix + 'dir#parent', parent
                 children && c.map{|c| yield uri, Posix + 'dir#child', c})
          node.stat.do{|s|[:size,:ftype,:mtime].map{|p| yield uri, Stat+p.to_s, (s.send p)}})
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

  # create node
  def dir
    e || FileUtils.mkdir_p(d)
    self
  end

  # create link
  def ln t
    t = t.E # cast bare URI/string to resource
    if !t.e  # destination exists?
#      puts "link #{t} > #{uri} | #{t.opaque?} #{t.no} > #{no}"
      t.no.dirname.dir # create containing dir
      FileUtils.symlink no, t.no # create link
    end
  end

  def touch
    FileUtils.touch no
    self
  end
    
  def deleteNode
    no.deleteNode if e
    self
  end

  def size
    no.size
  end

  def read
    f ? r : get
  end

  def get
    (open uri).read
  end

  # wrapped readFile - check if exists & maybe parse JSON
  def r p=false
    if f
      p ? (JSON.parse readFile) : readFile
    else
      puts "tried to open #{d}"
      nil
    end
  end

  # write file - make sure dir exists & serialize JSON if requested
  def w o,s=false
    puts "w #{uri} > #{d}"
    dirname.dir
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
  
  def dir
    puts "mkpath #{self}" unless exist?
    mkpath unless exist? 
  end

  # append to path
  def a s
    Pathname.new to_s+s
  end

  # path -> E
  def E
    to_s.force_encoding('UTF-8').unpathURI
  end

  def c
    return [] unless directory?
    children.delete_if{|n| n.basename.to_s.match /^\./}
    rescue
      []
  end
  
  def deleteNode
    FileUtils.send file? ? :rm : :rmdir,self
    parent.deleteNode if parent.c.empty?
  end

end

class File::Stat
  def utime
    mtime.to_i
  end
end
