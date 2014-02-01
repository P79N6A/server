#watch __FILE__
class E

  fn 'view/dir',->i,e{
    a = -> i { i = i.E
      {_: :a, href: i.localURL(e), c: i.uri.match(/(gif|jpe?g|png)$/i) ? {_: :img, src: i.uri+'?y=scaleImage&px=233'} : i.uri.sub(/.*\//,'')}}

    [(H.once e, 'dir', (H.css '/css/ls')),
     i.map{|u,r|
       url = r.E.localURL e
       {class: :dir, style: "background-color: #{E.cs}",    # dir wrapper
         c: [{c: [{_: :a, href: url.t + '?view=ls', c: r.uri.sub('http://'+e['SERVER_NAME'],'')},
                  {_: :a, href: url.t, c: '/'}]},
             r[Posix+'dir#child'].do{|c|c.map{|c|a[c]}}]}}]}

  F['view/'+MIMEtype+'inode/directory'] = F['view/dir']

  fn 'view/ls',->i,e{
    e.q['sort'] ||= 'stat:mtime'
    e.q['reverse'] ||= true
    dir = e['uri'].E
    path = dir.pathSegment
    up = (!path || path.uri == '/') ? '/' : dir.parent.url
    i = i.dup
    i.delete_if{|u,r|!r[Stat+'ftype']}
    f = {}
    ['uri', Posix+'dir#child', Stat+'ftype', Stat+'mtime', Stat+'size'].map{|p|f[p] = true}
    i.values.map{|r|
      r.class==Hash &&
      r.delete_if{|p,o|!f[p]}}
    [(H.css '/css/ls'),
     {_: :a, class: :up, href: up+'?view=ls', c: '&uarr;'},
     {class: :ls, c: (Fn 'view/table',i,e)},'<br clear=all>',
     {_: :a, class: :down, href: e['uri'].E.url.t, c: '&darr;'}]}

  fn 'set/find',->e,q,m,x=''{
    q['q'].do{|q|
      r = '-iregex ' + ('.*' + q + '.*' + x).sh
      s = q['size'].do{|s| s.match(/^\d+$/) && '-size +' + s + 'M'} || ""
      t = q['day'].do{|d| d.match(/^\d+$/) && '-ctime -' + d } || ""
      [e,e.pathSegment].compact.select(&:e).map{|e|
        `find #{e.sh} #{t} #{s} #{r} | head -n 1000`.
        lines.map{|l|l.chomp.unpathFs}}.compact.flatten}}

  fn 'view/find',->i,e{
    {_: :form, method: :GET, action: e['REQUEST_PATH'].t,
      c: [{_: :input, name: :set, value: :find, type: :hidden},
          {_: :input, name: :view, value: :ls, type: :hidden},
          {_: :input, name: :q, style: 'float: left;font-size:1.3em'}]}}

  fn 'protograph/du',->d,q,m{
    d.pathSegment.do{|path|
    GREP_DIRS.find{|p|path.uri.match p}.do{|ok|
      e = [d,path].compact.find &:e
      q['view'] ||= 'table'
      q['sort'] = Stat+'size'
      q['reverse'] = true
      m[e.uri] = e if e
      rand.to_s.h}}}

  fn 'graph/du',->e,_,m{
    `du -a #{m.values[0].sh}`.each_line{|l|
      s,p = l.chomp.split /\t/ # size, path
      p = p.unpathFs           # path -> URI
      m[p.uri] = {'uri' => p.uri,
        Posix+'util#du' => E[p.uri+'?graph=du#du'],
            Stat+'size' => [s.to_i]}}
    m }
  
end
