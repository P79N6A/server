#watch __FILE__
class E

  fn 'set/ls',->d,e,m{d.c}

  # filesystem metadata only
  fn 'graph/ls',->d,e,m{d.c.map{|c|c.fromStream m, :triplrInode, false}}

  # basic directory view 
  fn 'view/dir',->i,e{

    # localize URL
    h = 'http://' + e['HTTP_HOST'] + '/'
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
     i.map{|u,r| r['fs:child'] ? # directory?
       {class: :dir, style: "background-color: #{E.c}", # dir wrapper
         c: [{_: :a, href: l[r.uri]+'?graph=ls&view=ls', c: r.uri.sub( 'http://'+e['HTTP_HOST'],'')}, # dir link
             r['fs:child'].map{|c|a[c]}]} :  # children
       a[r]}]}                               # item

  F['view/inode/directory']=F['view/dir']

  # tabular rendering
  fn 'view/ls',->i,e{
    [(H.css '/css/ls'),{class: :ls, c: (Fn 'view/tab',i,e)},(Fn 'view/find',i,e),
     {_: :a, class: :du, href: e['REQUEST_PATH'].t+'??=du', c: :du}]}

end
