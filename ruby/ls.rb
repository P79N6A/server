#watch __FILE__
class E

  fn 'view/dir',->i,e{
    a = -> i { i = i.E
      {_: :a, href: i.localURL(e), c: i.uri.match(/(gif|jpe?g|png)$/i) ? {_: :img, src: i.uri+'?y=scaleImage&px=233'} : i.uri.sub(/.*\//,'')}}

    [(H.once e, 'dir', (H.css '/css/ls')),
     i.map{|u,r|
       if r[Posix+'dir#child']
         url = r.E.localURL e
         {class: :dir, style: "background-color: #{E.cs}",    # dir wrapper
           c: [{c: [{_: :a, href: url.t+'?view=ls', # link to "ls"
                      c: r.uri.sub( 'http://'+e['SERVER_NAME'],'')},
                    {_: :a, href: url.t, c: '/'}]},
               r[Posix+'dir#child'].map{|c|a[c]}]}
       else
         F['view/base'][{u => r},e]
       end }]}

  F['view/'+MIMEtype+'inode/directory'] = F['view/dir']

  fn 'view/ls',->i,e{
    dir = e['uri'].E
    path = dir.pathSegment
    up = (if !path || path.uri == '/'
            '/'
          else
            dir.parent.url.t+'?view=ls'
          end)

    [(H.css '/css/ls'),
     {_: :a, class: :up, href: up, c: '&uarr;'},
     {class: :ls,
       c: (Fn 'view/table',i,e)},
     (Fn 'view/find',i,e),'<br clear=all>',
     {_: :a, class: :down, href: e['uri'].E.url.t + e.q.except('view').qs, c: '&darr;'}]}
  
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
