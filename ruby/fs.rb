#watch __FILE__
class R

  fn 'view/'+Stat+'Directory',->i,e{
    a = -> i { i = i.R
      {_: :a, href: i.localURL(e), c: i.uri.match(/(gif|jpe?g|png)$/i) ? {_: :img, src: '/thumbnail'+i.pathSegment} : i.uri.sub(/.*\//,'')}}

    [(H.once e, 'dir', (H.css '/css/ls')),
     i.map{|u,r|
       url = r.R.localURL e
       {class: :dir, style: "background-color: #{R.cs}",    # dir wrapper
         c: [{c: [{_: :a, href: url.t + '?view=ls', c: r.uri.sub('http://'+e['SERVER_NAME'],'')},
                  {_: :a, href: url.t, c: '/'}]},
             r[LDP+'contains'].do{|c|c.map{|c|a[c]}}]}}]}

  fn 'view/ls',->i,e{
    dir = e['uri'].R
    path = dir.pathSegment
    up = (!path || path.uri == '/') ? '/' : dir.parent.url
    i = i.dup
    i.delete_if{|u,r|!r[Stat+'ftype']}
    f = {}
    ['uri', LDP+'contains', Stat+'ftype', Stat+'mtime', Stat+'size'].map{|p|f[p] = true}
    i.values.map{|r|
      r.class==Hash &&
      r.delete_if{|p,o|!f[p]}}
    [(H.css '/css/ls'),
     {_: :a, class: :up, href: up+'?view=ls', c: '&uarr;'},
     {class: :ls, c: F['view/table'][i,e]},'<br clear=all>',
     {_: :a, class: :down, href: e['uri'].R.url.t, c: '&darr;'}]}

  fn 'fileset/find',->e,q,m,x=''{
    q['q'].do{|q|
      r = '-iregex ' + ('.*' + q + '.*' + x).sh
      s = q['size'].do{|s| s.match(/^\d+$/) && '-size +' + s + 'M'} || ""
      t = q['day'].do{|d| d.match(/^\d+$/) && '-ctime -' + d } || ""
      [e,e.pathSegment].compact.select(&:e).map{|e|
        `find #{e.sh} #{t} #{s} #{r} | head -n 1000`.
        lines.map{|l|l.chomp.unpath}}.compact.flatten}}

  fn 'fileset/glob',->d,e=nil,_=nil{
    p = [d,d.pathSegment].compact.map(&:glob).flatten[0..4e2].compact.partition &:inside
    p[0] }

  fn 'fileset/depth',->d,r,m{ # depth-first
    global = !r.has_key?('local')
    p = global ? d.pathSegment : d
    loc = global ? '' : '&local'
    c = ((r['c'].do{|c|c.to_i} || 12) + 1).max(1024) # an extra for next-page pointer
    o = r['d'] =~ /^a/ ? :asc : :desc            # direction
    (p.take c, o, r['offset'].do{|o|o.R}).do{|s| # take subtree
      first, last = s[0], s.size > 1 && s.pop
      desc, asc = o == :asc ? [first,last] : [last,first]
      u = m['#']
      u[Type] = R[HTTP+'Response']
      u[Prev] = {'uri' => d.uri + "?set=depth&c=#{c-1}&d=desc#{loc}&offset=" + (URI.escape desc.uri)} if desc
      u[Next] = {'uri' => d.uri + "?set=depth&c=#{c-1}&d=asc#{loc}&offset=" + (URI.escape asc.uri)} if asc
      s }}

  def triplrInode
    if node.directory?
      yield uri, Type, R[LDP+'Container']
      yield uri, Type, R[Stat+'Directory']
      c.map{|c|
        yield uri, LDP+'contains', R[c.uri.gsub('?','%3F').gsub('#','%23')]}
    end
    node.stat.do{|s|[:size,:ftype,:mtime].map{|p| yield uri, Stat+p.to_s, (s.send p)}}
  end
  
  def triplrSymlink
    realpath.do{|t|
      target = t.to_s.index(FSbase)==0 ? t.R : t.to_s
      yield uri, '/linkTarget', target }
  end

  def triplrStdOut e,f='/',g=/^\s*(.*?)\s*$/,a=sh
    `#{e} #{a}|grep :`.each_line{|i|
      i = i.split /:/
    yield uri, (f + (i[0].match(g)||[0,i[0]])[1].       # s
     gsub(/\s/,'_').gsub(/\//,'-').gsub(/[\(\)]+/,'')), # p
      i.tail.join(':').strip.do{|v|v.match(/^[0-9\.]+$/) ? v.to_f : v}} # o
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

  def read p=false
    if f
      p ? (JSON.parse File.open(d).read) : File.open(d).read
    else
      nil
    end
  end

  def write o,s=false
    dirname.mk
    File.open(d,'w'){|f|
      f << (s ? o.to_json : o)}
    self
  end

  alias_method :e, :exist?
  alias_method :f, :file?
  alias_method :m, :mtime
  alias_method :r, :read
  alias_method :w, :write

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
