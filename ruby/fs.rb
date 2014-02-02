#watch __FILE__

%w{date digest/sha1 fileutils json open-uri pathname}.each{|r|require(r)}

class E

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

  def ln t
    t = t.E # cast bare URI/string to resource
    if !t.e # destination exist?
      t.dirname.mk
      FileUtils.link node, t.node
    end
  end

  def ln_s t
    t = t.E # cast bare URI/string to resource
    if !t.e # destination exist?
      t.dirname.mk
      FileUtils.symlink node, t.node
    end
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

  fn 'set/glob',->d,e=nil,_=nil{
    p = [d,d.pathSegment].compact.map(&:glob).flatten[0..4e2].compact.partition &:inside
    p[0] }

  fn 'req/randomFile',->e,r{
    g = F['set/glob'][e]
    !g.empty? ? [302, {Location: g[rand g.length].uri}, []] : [404]}

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
