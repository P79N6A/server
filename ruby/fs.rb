# -*- coding: utf-8 -*-
#watch __FILE__
class R

  def triplrFile
    if symlink?
      realURI.do{|t|
        yield t.uri, Type, R[Stat+'File']
        yield t.uri, Date, t.mtime.iso8601
        yield t.uri, Size, t.size
      }
    else
      yield uri, Type, R[Stat+'File']
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
    r = [] # docs
    r.push self if e
    %w{e ht html md n3 ttl txt}.map{|suffix|
      doc = docroot.a '.' + suffix
      r.push doc.setEnv(@r) if doc.e
    }
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
    e.path.match(/^\/([0-9]{4})\/([0-9]{2})\/([0-9]{2})\/?$/).do{|m| # paginate day-dirs
      t = ::Date.parse "#{m[1]}-#{m[2]}-#{m[3]}" # cast to date
      query = e.env['QUERY_STRING']
      qs = query && !query.empty? && ('?' + query) || ''
      pp = (t-1).strftime('/%Y/%m/%d/') # prev-day
      np = (t+1).strftime('/%Y/%m/%d/') # next-day
      this[Prev] = {'uri' => pp + qs} if R['//' + e.env.host + pp].e
      this[Next] = {'uri' => np + qs} if R['//' + e.env.host + np].e}
    if e.env[:container]
      cs = e.c # contained
      cs.map{|c|c.setEnv e.env} if cs.size < 17 # skip relURI prettiness on larger sets (for speed)
      e.fileResources.concat cs
    else
      e.fileResources.concat FileSet['rev'][e,q,g]
    end}

end
