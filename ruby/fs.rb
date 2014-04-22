# -*- coding: utf-8 -*-
#watch __FILE__
class R

  FileSet['default'] = -> e,q,g {
    s = []
    s.concat e.fileResources # host-specific
    e.justPath.do{|p| s.concat p.fileResources unless p.uri == '/'} # global
    e.env['REQUEST_PATH'].do{|path|
      path.match(/^\/([0-9]{4})\/([0-9]{2})\/([0-9]{2})\/$/).do{|m| # path a day-dir
        t = ::Date.parse "#{m[1]}-#{m[2]}-#{m[3]}" # Date object
        pp = (t-1).strftime('/%Y/%m/%d/') # prev day
        np = (t+1).strftime('/%Y/%m/%d/') # next day
        qs = q['view'].do{|v|'?view='+v} || ''
        g['#'][Prev] = {'uri' => pp + qs} if pp.R.e || R['//' + e.env['SERVER_NAME'] + pp].e
        g['#'][Next] = {'uri' => np + qs} if np.R.e || R['//' + e.env['SERVER_NAME'] + np].e }}
    s
  }

  FileSet['find'] = -> e,q,m,x='' {
    q['q'].do{|q|
      r = '-iregex ' + ('.*' + q + '.*' + x).sh
      s = q['size'].do{|s| s.match(/^\d+$/) && '-size +' + s + 'M'} || ""
      t = q['day'].do{|d| d.match(/^\d+$/) && '-ctime -' + d } || ""
      [e,e.justPath].compact.select(&:e).map{|e|
        `find #{e.sh} #{t} #{s} #{r} | head -n 1000`.
        lines.map{|l|l.chomp.unpath}}.compact.flatten}}

  FileSet['glob'] = -> d,e=nil,_=nil {
    p = [d,d.justPath].compact.map(&:glob).flatten[0..4e2].compact.partition &:inside
    p[0] }

  FileSet['paged'] = -> d,r,m {
    p = d.e ? d : (d.justPath.e ? d.justPath : d)
    c = ((r['c'].do{|c|c.to_i} || 8) + 1).max(1024) # one extra for next-page startpoint
    o = r['d'] =~ /^a/ ? :asc : :desc            # direction
    (p.take c, o, r['offset'].do{|o|o.R}).do{|s| # subtree
      first, last = s[0], s.size > 1 && s.pop
      desc, asc = o == :asc ? [first,last] : [last,first]
      u = m['#']
      u[Type] = R[HTTP+'Response']
      links = []
      if desc
        uri = d.uri + "?set=paged&c=#{c-1}&d=desc&offset=" + (URI.escape desc.uri)
        u[Prev] = {'uri' => uri}
        d.env[:Links].push "<#{uri}>; rel=prev"
      end
      if asc
        uri = d.uri + "?set=paged&c=#{c-1}&d=asc&offset=" + (URI.escape asc.uri)
        u[Next] = {'uri' => uri}
        d.env[:Links].push "<#{uri}>; rel=next"
      end
      s}}

  View[Stat+'File'] = -> i,e {
    [(H.once e, 'stat', (H.css '/css/ls')),
     i.map{|u,r|
       r[Stat+'size'].do{|s|
         {class: :File, c: [{_: :a, href: u, title: "#{u}  #{s[0]} bytes", c: '☁'+u.R.abbr+' '},
                            r[Content]]}}}]}

  View[Stat+'Directory'] = -> i,e {
    a = -> i { i = i.R
      {_: :a, href: i, c: i.uri.match(/(gif|jpe?g|png)$/i) ? {_: :img, src: '/thumbnail' + i.justPath} : i.uri.sub(/.*\//,' ')}}

    [(H.once e, 'stat', (H.css '/css/ls')),
     i.map{|u,r|
       resource = r.R
       uri = resource.uri.t
       {class: :dir, style: "background-color: #{R.cs}",
         c: [{c: {_: :a, href: uri, c: resource.abbr}},
             r[LDP+'contains'].do{|c|c.map{|c|a[c]}}]}}]}

  View['ls'] = -> i,e {
    dir = e[:Response]['URI'].R
    path = dir.justPath
    up = (!path || path.uri == '/') ? '/' : dir.parent.url
    i = i.dup
    i.delete_if{|u,r|!r[Stat+'size']}
    f = {}
    ['uri', LDP+'contains', Type, Stat+'mtime', Stat+'size'].map{|p|f[p] = true}
    i.values.map{|r|
      r.class==Hash &&
      r.delete_if{|p,o|!f[p]}}
    [(H.css '/css/ls'),
     {_: :a, class: :up, href: up+'?view=ls', c: '&uarr;'},
     {class: :ls, c: View['table'][i,e]},'<br clear=all>',
     {_: :a, class: :down, href: e[:Response]['URI'].R.url.t, c: '&darr;'}]}

  def fileResources
    [(self if e),
     docroot.glob(".{e,jsonld,md,n3,nt,rdf,ttl,txt}"),
     ((node.directory? && uri[-1]=='/') ? c : []) # trailing slash -> children
    ].flatten.compact
  end

  def triplrInode
    if node.directory?
      dir = stripSlash.uri
      yield dir, Type, R[LDP+'BasicContainer']
      yield dir, LDP+'firstPage', R[dir+'/?set=paged']
      c.map{|c|
        i = c.node.symlink? && c.realpath.do{|p|p.R.do{|r|r.docroot}} || c # dereference symlink
        yield dir, LDP+'contains', i
      }
    end
    node.stat.do{|s|
      yield uri, SIOC+'has_container', parent unless pathURI == '/'
      [:size,:mtime].map{|p| yield uri, Stat+p.to_s, (s.send p)}
      yield uri, Type, R[Stat + s.ftype.capitalize]} unless node.symlink?
  end

  def triplrStdOut e, f='/', g=/^\s*(.*?)\s*$/, a=sh
   yield uri, Type, (R MIMEtype+mimeP)
   `#{e} #{a}|grep :`.each_line{|i|
   begin
     i = i.split /:/
    yield uri, (f + (i[0].match(g)||[0,i[0]])[1].gsub(/\s/,'_').gsub(/\//,'-').gsub(/[\(\)]+/,'')),
      i.tail.join(':').strip.do{|v|v.match(/^[0-9\.]+$/) ? v.to_f : (v.match(HTTP_URI) ? v.R : v.hrefs)}
   rescue
    puts "#{uri} skipped: #{i}"
   end}
  end

  def ln t, y=:link
    t = t.R
    t = t.uri[0..-2].R if t.uri[-1] == '/'
    if !t.e
      t.dirname.mk
      FileUtils.send y, node, t.node
    end
  end

  def delete;   node.deleteNode if e; self end
  def exist?;   node.exist? end
  def file?;    node.file? end
  def ln_s t; ln t, :symlink end
  def mtime;    node.stat.mtime if e end
  def touch;    FileUtils.touch node; self end

  def mk
    e || FileUtils.mkdir_p(d)
    self
  rescue Exception => x
    puts x
    self
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
    dirname.mk
    File.open(d,'w'){|f|
      f << (s ? o.to_json : o)}
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

  def R; to_s.force_encoding('UTF-8').unpath end

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
