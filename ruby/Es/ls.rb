#watch __FILE__
class E

  fn 'view/dir',->i,e{

    # item link + preview
    a = -> i { i = i.E
      {_: :a, href: i.localURL(e),
        c: i.uri.match(/(gif|jpe?g|png)$/i) ? {_: :img, src: i.uri+'?y=scaleImage&px=233'} : i.uri.sub(/.*\//,'')}}

    [(H.once e, 'dir', (H.css '/css/ls')),
     i.map{|u,r|
       if r[Posix+'dir#child']
         url = r.E.localURL e
         {class: :dir, style: "background-color: #{E.cs}",    # dir wrapper
           c: [{c: [{_: :a, href: url.t+'?view=ls&triplr=id', # link to "ls"
                      c: r.uri.sub( 'http://'+e['SERVER_NAME'],'')},
                    {_: :a, href: url.t, c: '/'}]},
               r[Posix+'dir#child'].map{|c|a[c]}]}
       else
         a[r]
       end
     }]}

  F['view/'+MIMEtype+'inode/directory'] = F['view/dir']

  fn 'view/ls',->i,e{
    dir = e['uri'].E
    path = dir.pathSegment
    up = (if !path || path.uri == '/'
            '/'
          else
            dir.parent.url.t+'?view=ls&triplr=id'
          end)

    [(H.css '/css/ls'),
     {_: :a, class: :up, href: up, c: '&uarr;'},
     {class: :ls,
       c: (Fn 'view/table',i,e)},
     (Fn 'view/find',i,e),'<br clear=all>',
     {_: :a, class: :down, href: e['uri'].E.url.t + e.q.except('triplr','view').qs, c: '&darr;'}]}
  
  # if a req got this far, try to use an index.html
  # you can safely delete this
  fn '/GET',->e,r{

    html = e.as 'index.html'
    if html.e
      if e.uri[-1] == '/'   # inside dir?
        html.env(r).getFile # show index
      else                  # descend to indexed dir
        [301, {Location: e.uri.t}, []] # redirect
      end
    else
      # continue to default response
      e.response
    end}

end
