#watch __FILE__
class E

  fn 'set/ls',->d,e,m{d.c}

  # filesystem metadata only
  fn 'graph/ls',->d,e,m{d.c.map{|c|c.fromStream m, :triplrInode, false}}

  fn 'set/subtree',->d,r,m{
    c =(r['c'].do{|c|c.to_i + 1} || 3).max(100) # one extra for start of next-page
    o = r['d'] =~ /^a/ ? :asc : :desc           # direction
    ('/'.E.take c, o, d.uri).do{|s|             # take subtree
      desc, asc = o == :desc ?                  # orient pagination hints
      [s.pop, s[0]] : [s[0], s.pop]
      m['prev'] = {'uri' => 'prev', 'url' => desc.url,'d' => 'desc'}
      m['next'] = {'uri' => 'next', 'url' => asc.url, 'd' => 'asc'}
      s }}

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
         c: [{_: :a, href: l[r.uri]+'?graph=ls&view=ls', c: r.uri}, # dir link
             r['fs:child'].map{|c|a[c]}]} :  # children
       a[r]}]}                               # item

  F['view/inode/directory']=F['view/dir']

  # tabular rendering
  fn 'view/ls',->i,e{
    [(H.css '/css/ls'),{class: :ls, c: (Fn 'view/tab',i,e)},(Fn 'view/find',i,e),
     {_: :a, class: :du, href: e['REQUEST_PATH'].t+'??=du', c: :du}]}
     
end
