%w{date digest/sha1 fileutils json open-uri pathname}.each{|r|require(r)}

class NilClass
  def unpath
    E ""
  end
end

class E

  def d
    node.to_s
  end

  def node
    Pathname.new B + path
  end
  alias_method :no, :node

  # glob :: pattern -> [E]
  def glob p=""
    (Pathname.glob d + p).map &:E
  end

  def parent
    E Pathname.new(uri).parent
  end

  def siblings
    parent.c
  end

  def jail
    no.expand_path.to_s.index(E::B)==0 && @r['PATH_INFO'] !~ /\.\./ && self
  end

  def c
    no.c.map &:E
  end
  alias_method :children, :c


  # node exists?
  def e
    no.exist?
  end

  # directory?
  def d?
    no.directory?
  end

  # file?
  def f
    no.file?
  end

  # modification time
  def m
    no.stat.mtime if e
  end

  def tripleSourceNode r=true
    e && (d? && (yield uri,'fs:parent',parent
             r && c.map{|c|yield uri,'fs:child',c})
      node.stat.do{|s|[:size,:ftype,:mtime].map{|p|
          yield uri,'fs:'+p.to_s,(s.send p)}})
  end
  
  # create node
  def dir
    e || FileUtils.mkdir_p(d)
    self
#  rescue
#    self
  end

  # create link
  def ln t
    t = E(t) # cast bare URI/string to resource
    if !t.e  # destination exists?
      t.no.dirname.dir # ensure containing dir exists
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

  # read file - check if it exists & parse JSON if requested
  def r p=false
    if f
      (p ? JSON.parse(readFile)[0] : readFile)
    else
    p ? {} : nil
    end
  rescue
    p ? {} : nil
  end

  # write file - make sure dir exists & serialize JSON if requested
  def w o,s=false
    dirname.dir
    writeFile (s ? [o].to_json : o)
    self
  rescue
    self
  end

  def writeFile c
    File.open(d,'w'){|f|f << c}
  end

  def readFile
    File.open(d).read
  end

  def readlink
    no.symlink? ? no.readlink.E : self
  end

end

class Pathname
  
  def dir
    mkpath unless exist? 
  end

  # append to path
  def a s
    Pathname.new to_s+s
  end

  # path -> E
  def E
    (to_s.force_encoding('UTF-8')[E::Blen+1..-1]||'').unpath false
  end

  def c
    return [] unless directory?
    children.delete_if{|n| n.basename.to_s.match /^(\.+|#{E::S})$/}
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
