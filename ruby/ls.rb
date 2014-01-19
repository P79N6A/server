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

  fn 'protograph/du',->d,_,m{
    e = [d,d.pathSegment].compact.find &:e
    puts _.class
    m[e.uri] = e if e
    rand.to_s.h }

  fn 'graph/du',->e,_,m{
    `du -a #{m.values[0].sh}`.each_line{|l|
      s,p = l.chomp.split /\t/ # size, path
      p = p.unpathFs           # path -> URI
      m[p.uri] = {'uri' => p.uri,
            Stat+'size' => [s.to_i]}}
    m }
  
end
