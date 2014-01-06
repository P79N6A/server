watch __FILE__
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
    dir = e['uri'].E; path = dir.pathSegment
    up = (!path || path.uri == '/') ? '/' : dir.parent.url
    i = i.dup; f = {}
    ['uri', Posix+'dir#child', Stat+'ftype', Stat+'mtime', Stat+'size'].map{|p|f[p] = true}
    i.delete_if{|u,r|!r[Stat+'ftype']}
    i.values.map{|r|
      r.class==Hash &&
      r.delete_if{|p,o|!f[p]}}
    [(H.css '/css/ls'),
     {_: :a, class: :up, href: up, c: '&uarr;'},
     {class: :ls,
       c: (Fn 'view/table',i,e)},
     (Fn 'view/find',i,e),'<br clear=all>',
     {_: :a, class: :down, href: e['uri'].E.url.t, c: '&darr;'}]}
  
  # user-patchable default-handler
  fn '/GET',->e,r{
    x = 'index.html'
    i = [e,e.pathSegment].compact.map{|e|e.as x}.find &:e
    if i
      if e.uri[-1] == '/' # inside dir?
        i.env(r).getFile  # show index
      else                # descend to indexed dir
        [301, {Location: e.uri.t}, []]
      end
    else
      # default handler
      e.response
    end}

end
