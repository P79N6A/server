#watch __FILE__
class E

  fn 'set/ls',->d,e,m{d.c}

  # filesystem metadata only
  fn 'graph/ls',->d,e,m{d.c.map{|c|c.fromStream m, :triplrInode, false}}

  # basic directory view 
  fn 'view/dir',->i,e{

    # localize URL
    h = 'http://' + e['SERVER_NAME'] + '/'
    l = -> u {
      if u.index(h) == 0
        u # already a local link
      else
        # generate local link
        Prefix + u
      end}

    # item thumbnail / link
    a = -> i { e = i.E
      {_: :a, href: l[e.uri],
        c: e.uri.match(/(gif|jpe?g|png)$/i) ? {_: :img, src: i.uri+'?233x233'} :
        e.uri.sub(/.*\//,'')
      }}

    [(H.once e, 'dir', (H.css '/css/ls')),
     i.map{|u,r| r[Posix+'dir#child'] ? # directory?
       {class: :dir, style: "background-color: #{E.c}", # dir wrapper
         c: [{c: [{_: :a, href: l[r.uri]+'?graph=ls&view=ls', c: r.uri.sub( 'http://'+e['SERVER_NAME'],'')}, # link to ls
                  {_: :a, href: l[r.uri].t, c: '/'}]},
             r[Posix+'dir#child'].map{|c|a[c]}]} :  # children
       a[r]}]}                               # item

  F['view/'+MIMEtype+'inode/directory']=F['view/dir']

  # tabular rendering
  fn 'view/ls',->i,e{
    [(H.css '/css/ls'),
     {_: :a, class: :up, href: E(e['uri']).parent.url+'?graph=ls&view=ls', c: '&uarr;'},
     {class: :ls,
       c: (Fn 'view/tab',i,e)},
     {_: :a, class: :du, href: e['REQUEST_PATH'].t+'??=du', c: :du, rel: :nofollow},
     (Fn 'view/find',i,e),'<br clear=all>',
     {_: :a, class: :down, href: e['uri'].E.url.t, c: '&darr;'},
    ]}

end
