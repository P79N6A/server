# -*- coding: utf-8 -*-
#watch __FILE__
class R

  def triplrDir
    yield uri, Type, R[Directory]
    yield uri, Stat+'mtime', mtime.to_i
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
        yield t.uri, Stat+'mtime', mtime}
    else
      yield uri, Type, R[Stat+'File']
      yield uri, Stat+'mtime', mtime
      yield uri, Size, size
    end
  end

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

  def writeFile o,s=false
    dir.mk
    File.open(pathPOSIX,'w'){|f|
      f << (s ? o.to_json : o)}
    self
  rescue Exception => x
    puts caller[0..2],x
    self
  end

  def mkdir
    e || FileUtils.mkdir_p(pathPOSIX)
    self
  rescue Exception => x
    puts x
    self
  end

  alias_method :r, :readFile
  alias_method :w, :writeFile
  alias_method :mk, :mkdir

  def fileResources
    r = []
    r.push self if e # exact match
    %w{e html md n3 ttl txt}.map{|suffix|
      doc = docroot.a '.' + suffix
      r.push doc if doc.e } # related thru docbase
    r
  end

  def glob
    (Pathname.glob pathPOSIX).map &:R
  end

  ViewGroup[Stat+'File'] = ViewGroup[CSVns+'Row']

  FileSet[Resource] = -> e,q,g {
    this = g['']
    e.path.match(/^\/([0-9]{4})\/([0-9]{2})\/([0-9]{2})\/?$/).do{|m| # day-dir
      t = ::Date.parse "#{m[1]}-#{m[2]}-#{m[3]}"
      pp = (t-1).strftime('/%Y/%m/%d/') # prev-day
      np = (t+1).strftime('/%Y/%m/%d/') # next-day
      this[Prev] = {'uri' => pp} if pp.R.e || R['//' + e.env['SERVER_NAME'] + pp].e
      this[Next] = {'uri' => np} if np.R.e || R['//' + e.env['SERVER_NAME'] + np].e}
    if e.env[:container] # contained set
      e.fileResources.concat e.c.map{|c|c.setEnv(e.env).bindHost}
    else
      e.fileResources
    end}

end
