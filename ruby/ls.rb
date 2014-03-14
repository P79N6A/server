#watch __FILE__
class R

  fn 'view/dir',->i,e{
    a = -> i { i = i.R
      {_: :a, href: i.localURL(e), c: i.uri.match(/(gif|jpe?g|png)$/i) ? {_: :img, src: i.uri+'?y=scaleImage&px=233'} : i.uri.sub(/.*\//,'')}}

    [(H.once e, 'dir', (H.css '/css/ls')),
     i.map{|u,r|
       url = r.R.localURL e
       {class: :dir, style: "background-color: #{R.cs}",    # dir wrapper
         c: [{c: [{_: :a, href: url.t + '?view=ls', c: r.uri.sub('http://'+e['SERVER_NAME'],'')},
                  {_: :a, href: url.t, c: '/'}]},
             r[Posix+'dir#child'].do{|c|c.map{|c|a[c]}}]}}]}

  F['view/'+MIMEtype+'inode/directory'] = F['view/dir']

  fn 'view/ls',->i,e{
    dir = e['uri'].R
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
     {class: :ls, c: F['view/table'][i,e]},'<br clear=all>',
     {_: :a, class: :down, href: e['uri'].R.url.t, c: '&darr;'}]}

  fn 'set/find',->e,q,m,x=''{
    q['q'].do{|q|
      r = '-iregex ' + ('.*' + q + '.*' + x).sh
      s = q['size'].do{|s| s.match(/^\d+$/) && '-size +' + s + 'M'} || ""
      t = q['day'].do{|d| d.match(/^\d+$/) && '-ctime -' + d } || ""
      [e,e.pathSegment].compact.select(&:e).map{|e|
        `find #{e.sh} #{t} #{s} #{r} | head -n 1000`.
        lines.map{|l|l.chomp.unpath}}.compact.flatten}}

  fn 'set/glob',->d,e=nil,_=nil{
    p = [d,d.pathSegment].compact.map(&:glob).flatten[0..4e2].compact.partition &:inside
    p[0] }

end
