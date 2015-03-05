# -*- coding: utf-8 -*-
#watch __FILE__
class R

  def triplrDir
    yield uri, Type, R[Directory]
    yield uri, Date, mtime.iso8601
    contained = c
    yield uri, Size, contained.size
    if contained.size <= 32
      contained.map{|c|
        yield uri, LDP+'contains', c.setEnv(@r).bindHost.stripDoc}
    end
  end

  def triplrFile &f
    if symlink?
      realURI.do{|t|
        mtime = t.mtime.to_i
        t = t.stripDoc
        yield t.uri, Type, R[Resource]
        yield t.uri, Date, mtime.iso8601}
    else
      yield uri, Type, R[Stat+'File']
      yield uri, Type, R[GraphData] if RDFsuffixes.member? ext
      yield uri, Date, mtime.iso8601
      yield uri, Size, size
    end
  end

  def realpath # find real file after all the symlinks
    node.realpath
  rescue Exception => x
    puts x
  end
  def realURI; realpath.do{|p|p.R} end

  def readFile parseJSON=false
    if f
      if parseJSON
        begin
          JSON.parse File.open(pathPOSIX).read
        rescue Exception => x
          puts "error reading JSON: #{caller} #{uri} #{x}"
          {}
        end
      else
        File.open(pathPOSIX).read
      end
    else
      nil
    end
  end
  alias_method :r, :readFile

  def appendFile line
    dir.mk
    File.open(pathPOSIX,'a'){|f|f.write line + "\n"}
  end

  def writeFile o,s=false
    dir.mk
    File.open(pathPOSIX,'w'){|f|
      f << (s ? o.to_json : o)}
    self
  rescue Exception => x
    puts caller[0..2],x
    self
  end
  alias_method :w, :writeFile

  def mkdir
    e || FileUtils.mkdir_p(pathPOSIX)
    self
  rescue Exception => x
    puts x
    self
  end
  alias_method :mk, :mkdir

  def ln t, y=:link
    t = t.R.stripSlash
    unless t.e || t.symlink?
      t.dir.mk
      FileUtils.send y, node, t.node
    end
  end

  def ln_s t; ln t, :symlink end

  def fileResources
    r = []
    r.push self if e # exact match
    %w{e ht html md n3 ttl txt}.map{|suffix|
      doc = docroot.a '.' + suffix
      r.push doc if doc.e } # related thru docbase
    r
  end

  def glob
    (Pathname.glob pathPOSIX).map &:R
  end

  def exist?;   node.exist? end
  alias_method :e, :exist?
  def directory?; node.directory? end
  def file?;    node.file? end
  alias_method :f, :file?
  def symlink?; node.symlink? end
  def mtime;    node.stat.mtime if e end
  alias_method :m, :mtime
  def size;     node.size end

  ViewGroup[Directory] = ViewGroup[Stat+'File'] = TabularView

  FileSet[Resource] = -> e,q,g {
    this = g['']
    e.path.match(/^\/([0-9]{4})\/([0-9]{2})\/([0-9]{2})\/?$/).do{|m| # day-dir
      t = ::Date.parse "#{m[1]}-#{m[2]}-#{m[3]}"
      qs = '?' + e.env['QUERY_STRING']
      pp = (t-1).strftime('/%Y/%m/%d/') # prev-day
      np = (t+1).strftime('/%Y/%m/%d/') # next-day
      this[Prev] = {'uri' => pp+qs} if R['//' + e.env.host + pp].e
      this[Next] = {'uri' => np+qs} if R['//' + e.env.host + np].e}
    if e.env[:container] #&& e.basename[0] != '.'
      e.fileResources.concat e.c.map{|c|c.setEnv(e.env).bindHost}
    else
      e.fileResources
    end}

end
