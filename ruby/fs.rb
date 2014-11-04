# -*- coding: utf-8 -*-
#watch __FILE__
class R

  def triplrInode &f
    file = URI.escape uri
    if directory?
      [R[Stat+'Directory'], R[LDP+'BasicContainer']].map{|type|
        yield uri, Type, type}
      yield uri, Stat+'mtime', mtime.to_i
      contained = c
      yield uri, Stat+'size', contained.size
      contained.map{|c| yield uri, LDP+'contains', c.setEnv(@r).bindHost.stripDoc} if contained.size < 27

    elsif symlink?
      readlink.do{|t|
        mtime = t.mtime.to_i
        t = t.stripDoc
        yield t.uri, Type, Resource
        yield t.uri, Stat+'mtime', mtime
        yield t.uri, Stat+'size', 0}

    else
      resource = URI.escape stripDoc.uri
      if resource != file
        yield resource, Type, Resource
        yield resource, Stat+'mtime', mtime.to_i
        yield resource, Stat+'size', size
      else
        yield file, Type, R[Stat+'File']
        yield file, Stat+'mtime', mtime.to_i
        yield file, Stat+'size', size
      end
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
    %w{e html md n3 ttl txt}.map{|suffix|
      doc = docroot.a '.' + suffix
      r.push doc if doc.e } # related thru docbase
    r.push self if e # exact path
    r
  end

  FileSet['default'] = -> e,q,g {
    e.env['REQUEST_PATH'].do{|path|
      path.match(/^\/([0-9]{4})\/([0-9]{2})\/([0-9]{2})\/?$/).do{|m| # day-dir
        t = ::Date.parse "#{m[1]}-#{m[2]}-#{m[3]}"
        pp = (t-1).strftime('/%Y/%m/%d/') # prev-day page
        np = (t+1).strftime('/%Y/%m/%d/') # next-day page
        g['#'][Prev] = {'uri' => pp} if pp.R.e || R['//' + e.env['SERVER_NAME'] + pp].e
        g['#'][Next] = {'uri' => np} if np.R.e || R['//' + e.env['SERVER_NAME'] + np].e}}
    e.env[:filemeta] = true if e.env[:container]
    e.env[:container] ? e.c.map{|c|c.setEnv(e.env).bindHost} : e.fileResources}

end
