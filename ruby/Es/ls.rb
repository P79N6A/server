#watch __FILE__
class E

  # basic directory view 
  fn 'view/dir',->i,e{

    # item link + preview
    a = -> i { i = i.E
      {_: :a, href: i.localURL(e),
        c: i.uri.match(/(gif|jpe?g|png)$/i) ? {_: :img, src: i.uri+'?233x233'} : i.uri.sub(/.*\//,'')}}

    [(H.once e, 'dir', (H.css '/css/ls')),
     i.map{|u,r|
       # directory?
       if r[Posix+'dir#child']
         url = r.E.localURL e
         {class: :dir, style: "background-color: #{E.cs}", # dir wrapper
           c: [{c: [{_: :a, href: url.t+'?view=ls&triplr=id', # link to ls
                      c: r.uri.sub( 'http://'+e['SERVER_NAME'],'')},
                    {_: :a, href: url.t, c: '/'}]},
               r[Posix+'dir#child'].map{|c|a[c]}]}   # children
       else
         a[r]
       end
     }]}

  F['view/'+MIMEtype+'inode/directory']=F['view/dir']

  # tabular rendering
  fn 'view/ls',->i,e{
    dir = e['uri'].E
    up = (if dir.pathSegment.uri == '/'
            '/'
          else
            dir.parent.url.t+'?view=ls&triplr=id'
          end)

    [(H.css '/css/ls'),
     {_: :a, class: :up, href: up, c: '&uarr;'},
     {class: :ls,
       c: (Fn 'view/tab',i,e)},
     (Fn 'view/find',i,e),'<br clear=all>',
     {_: :a, class: :down, href: e['uri'].E.url.t, c: '&darr;'}]}

end
