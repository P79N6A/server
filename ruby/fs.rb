# -*- coding: utf-8 -*-
#watch __FILE__
class R
  
  def triplrInode deep=true, &f
    if directory?
      d = descend.uri
      yield d, Stat+'size', size
      yield d, Stat+'mtime', mtime.to_i
      [R[Stat+'Directory'], R[LDP+'BasicContainer']].map{|type| yield d, Type, type}
      c.map{|c|c.triplrInode false, &f} if deep

    elsif symlink?
      [R[Stat+'Link'], Resource].map{|type| yield uri, Type, type}
      yield uri, Stat+'mtime', Time.now.to_i
      yield uri, Stat+'size', 0
      readlink.do{|t|
        yield uri, Stat+'target', t
        yield t.uri, Type, Resource}

    else
      u = deep ? uri : stripDoc.uri
      yield u, Type, R[Stat+'File'] if deep
      yield u, Type, Resource
      yield u, Stat+'size', size
      yield u, Stat+'mtime', mtime.to_i
    end
  end

  def node
    Pathname.new pathPOSIX
  end

  FileSet['default'] = -> e,q,g {
    s = []
    s.concat e.fileResources # host-specific
    e.justPath.do{|p| s.concat p.setEnv(e.env).fileResources unless p.uri == '/'} # path
    e.env['REQUEST_PATH'].do{|path|
      path.match(/^\/([0-9]{4})\/([0-9]{2})\/([0-9]{2})\/$/).do{|m| # path a day-dir
        t = ::Date.parse "#{m[1]}-#{m[2]}-#{m[3]}" # Date object
        pp = (t-1).strftime('/%Y/%m/%d/') # prev day
        np = (t+1).strftime('/%Y/%m/%d/') # next day
        qs = q['view'].do{|v|'?view='+v} || ''
        g['#'][Prev] = {'uri' => pp + qs} if pp.R.e || R['//' + e.env['SERVER_NAME'] + pp].e
        g['#'][Next] = {'uri' => np + qs} if np.R.e || R['//' + e.env['SERVER_NAME'] + np].e
        g['#'][Type] = R[HTTP+'Response'] if g['#'][Next] || g['#'][Prev]
      }}
    s}

  def inside; node.expand_path.to_s.index(FSbase) == 0 end

  FileSet['find'] = -> e,q,m,x='' {
    q['q'].do{|q|
      r = '-iregex ' + ('.*' + q + '.*' + x).sh
      s = q['size'].do{|s| s.match(/^\d+$/) && '-size +' + s + 'M'} || ""
      t = q['day'].do{|d| d.match(/^\d+$/) && '-ctime -' + d } || ""
      [e,e.justPath].compact.select(&:e).map{|e|
        `find #{e.sh} #{t} #{s} #{r} | head -n 1000`.
        lines.map{|l|R.unPOSIX l.chomp}}.compact.flatten}}

  def glob a = ""
    (Pathname.glob pathPOSIX + a).map &:R
  end

  FileSet['glob'] = -> d,e=nil,_=nil {
    p = [d,d.justPath].compact.map(&:glob).flatten[0..4e2].compact.partition &:inside
    p[0] }

  View['ls'] = ->d=nil,e=nil {
    keys = ['uri',Stat+'size',Type,Date,Title]
    [{_: :table,
       c: [{_: :tr, c: keys.map{|k|{_: :th, c: k.R.abbr}}},
           d.values.map{|e|
             {_: :tr, c: keys.map{|k| {_: :td, c: k=='uri' ? e.R.html : e[k].html}}}}]},
     H.css('/css/table')]}

  View[Stat+'File'] = -> i,e {
    [(H.once e, 'container', (H.css '/css/container')),
     i.map{|u,r|
       r[Stat+'size'].do{|s|
         {class: :File, c: [{_: :a, href: u, title: "#{u}  #{s[0]} bytes", c: '☁'+u.R.abbr+' '},
                            r[Content]]}}}]}

  def fileResources
    [(self if e), docroot.glob(".{e,ht,jsonld,md,n3,nt,rdf,ttl,txt}")].flatten.compact
  end

  def triplrStdOut e, f='/', g=/^\s*(.*?)\s*$/, a=sh
   yield uri, Type, (R MIMEtype+mime)
   `#{e} #{a}|grep :`.each_line{|i|
   begin
     i = i.split /:/
    yield uri, (f + (i[0].match(g)||[0,i[0]])[1].gsub(/\s/,'_').gsub(/\//,'-').gsub(/[\(\)]+/,'')),
      i.tail.join(':').strip.do{|v|v.match(/^[0-9\.]+$/) ? v.to_f : (v.match(HTTP_URI) ? v.R : v.hrefs)}
   rescue
    puts "#{uri} skipped: #{i}"
   end}
  end

  def readlink; node.readlink.R end

  def ln t, y=:link
    t = t.R.stripSlash
    unless t.e || t.symlink?
      t.dir.mk
      FileUtils.send y, node, t.node
    end
  end
  def ln_s t;   ln t, :symlink end

  def children; node.c.map &:R end
  alias_method :c, :children
  alias_method :d, :pathPOSIX
  def delete;   node.deleteNode if e; self end
  def exist?;   node.exist? end
  def directory?; node.directory? end
  def file?;    node.file? end
  def symlink?; node.symlink? end
  def mtime;    node.stat.mtime if e end
  def realpath; node.realpath rescue nil end
  def sh;       d.force_encoding('UTF-8').sh end
  def size;     node.size end
  def touch;    FileUtils.touch node; self end

  def mk
    e || FileUtils.mkdir_p(d)
    self
  rescue Exception => x
    puts x
    self
  end

  def MKCOL
#    return [401, {}, ["Unauthorized"]]     unless @r.user # require webID login
    return [403, {}, ["Forbidden"]]        unless allowWrite
    return [409, {}, ["parent not found"]] unless dir.exist?
    return [405, {}, ["file exists"]]      if file?
    return [405, {}, ["dir exists"]]       if directory?
    mk;    [200, {}, []]
  end

  def readFile parseJSON=false
    if f
      if parseJSON
        begin
          JSON.parse File.open(d).read
        rescue Exception => x
          puts "error reading JSON: #{caller} #{uri} #{x}"
          {}
        end
      else
        File.open(d).read
      end
    else
      nil
    end
  end

  def writeFile o,s=false
    dir.mk
    File.open(d,'w'){|f|
      f << (s ? o.to_json : o)}
    self
  rescue Exception => x
    puts caller[0..2],x
    self
  end

  alias_method :e, :exist?
  alias_method :f, :file?
  alias_method :m, :mtime
  alias_method :r, :readFile
  alias_method :w, :writeFile

  def take *a
    node.take(*a).map &:R
  end

end

class Pathname

  def R
    R.unPOSIX to_s.force_encoding('UTF-8')
  end

  def c
    return [] unless directory?
    children.delete_if{|n| n.basename.to_s.match /^\./}
    rescue
      []
  end
  
  def deleteNode
    FileUtils.send (file?||symlink?) ? :rm : :rmdir, self
    parent.deleteNode if parent.c.empty? # GC empty-container(s)
  end

  def take count=1000, direction=:desc, offset=nil
    offset = offset.d if offset

    ok = false    # in-range mark
    set=[]
    v,m={asc:      [:id,:>=],
        desc: [:reverse,:<=]}[direction]

    visit=->nodes{
      nodes.sort_by(&:to_s).send(v).each{|n|
        ns = n.to_s
        return if 0 >= count
        (ok || # already in-range
         !offset || # no offset required
         (sz = [ns,offset].map(&:size).min
          ns[0..sz-1].send(m,offset[0..sz-1]))) &&
        (if !(c = n.c).empty? # has children?
           visit.(c)          # visit children
         else
           count = count - 1 # decrement nodes-left count
           set.push n        # add node to result-set
           ok = true         # mark iterator as within range
        end )}}

    visit.(c)
    set
  end

end
