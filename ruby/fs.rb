# -*- coding: utf-8 -*-
#watch __FILE__
class R

  def triplrInode &f
    file = URI.escape uri
    if directory?
      d = descend.uri
      [R[Stat+'Directory'], R[LDP+'BasicContainer']].map{|type|
        yield d, Type, type}
      yield d, Stat+'size', size
      yield d, Stat+'mtime', mtime.to_i

    elsif symlink?
      readlink.do{|t|
        mtime = t.mtime.to_i
#        yield file, Type, R[Stat+'File'] # source triples
#        yield file, Stat+'mtime', mtime
#        yield file, Stat+'size', 0
        t = t.stripDoc
        yield t.uri, Type, Resource      # target triples
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
    s = []
    s.concat e.fileResources
    if e.directory?
      e.env[:directory] = true
      s.concat e.c # contained resources
    end
    e.env['REQUEST_PATH'].do{|path| # auto-paginate day-dirs 
      path.match(/^\/([0-9]{4})\/([0-9]{2})\/([0-9]{2})\/?$/).do{|m|
        t = ::Date.parse "#{m[1]}-#{m[2]}-#{m[3]}"
        pp = (t-1).strftime('/%Y/%m/%d/') # prev day
        np = (t+1).strftime('/%Y/%m/%d/') # next day
        g['#'][Prev] = {'uri' => pp} if pp.R.e || R['//' + e.env['SERVER_NAME'] + pp].e
        g['#'][Next] = {'uri' => np} if np.R.e || R['//' + e.env['SERVER_NAME'] + np].e
      }}
    s }

  View[Stat+'File'] = -> i,e {
    [(H.once e, 'container', (H.css '/css/container')),
     i.map{|u,r|
       r[Stat+'size'].do{|s|
         {class: :File, title: "#{u}  #{s[0]} bytes",
           c: ["\n", {_: :a, class: :file, href: u, c: '☁'}, # link to file ("download", original MIME)
               "\n", {_: :a, class: :view, href: u.R.stripDoc.a('.html'), c: u.R.abbr}, # link HTML representation of file
               "\n", r[Content], "\n"]}}}]}

end
