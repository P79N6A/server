watch __FILE__
class E
  
  fn 'set/ls',->d,e,m{d.c}
  fn 'graph/ls',->d,e,m{d.c.map{|c|c.fromStream m,:tripleSourceNode,false}}

  fn 'view/dir',->i,e{
    a = -> i { e = i.E
      [' ', e.uri.match(/(gif|jpe?g|png)$/i) ?
       {_: :a, href: e.uri, c: {_: :img, src: i.uri+'?64x64'}} : e.html]}
    [(H.css '/css/ls'),{_: :a, href: e['REQUEST_PATH']+'?graph=ls&view=ls', c: 'ls', class: :mode},
     i.map{|u,r| r['fs:child'] ?
       {class: :dir, style: "background-color: #{E.c}",
         c: [{_: :b, c: r.E.html},
             r['fs:child'].map{|c|a[c]}]} :
       a[r]}]}

  fn 'view/ls',->i,e{
    [(H.css '/css/ls'),(Fn 'view/tab',i,e),(Fn 'view/find',i,e),
     {_: :a, class: :du, href: e['REQUEST_PATH'].t+'??=du', c: :du}]}

  fn 'req/guessFiles',->e,r{ g = {}
    Fn 'graph/ls', e, nil, g
    g.values.map{|e|e.E.base}.do{|b|
      s = b.size.to_f
      # email
      if b.grep(/^msg\./).size / s > 0.42
        [302, {Location: e.uri+'?set=ls&view=threads'},[]]
      # audio
      elsif b.grep(/(aif|wav|flac|mp3|m4a|aac|ogg)$/i).size / s > 0.8
        [302, {Location: e.uri+'?graph=ls&view=audioplayer'},[]]
      # images
      elsif b.grep(/(gif|jpe?g|png)$/i).size / s > 0.8
        [302, {Location: e.uri+'?graph=ls&view=th'},[]]
      # default
      else
        [302, {Location: e.uri+'?graph=ls&view=dir'},[]]
      end}}
  
  # path-history breadcrumbs in iframe parents
  fn 'view/inode/directory',->i,e{
    [H.css('/css/ls'),(H.js '/js/ls'),(H.js '/js/mu'),
     i.values.map{|u|
       u['fs:child'].do{|c| o = E.c # color 
         d = c.select{|c|c.E.d?} # child directories        
         [{style: "background-color:#{E.c}",c: d.sort_by(&:uri).map{|c|
            [{_: :a,href: c.uri,target: o.tail,class: :child,style: "opacity:#{rand(40)/100.0+0.6};background-color: #{o}",c: c.E.base},' ']}},
          H.once(e,'child',{_: :iframe,name: o.tail, seamless: "",scrolling: :no,src: u.uri+'?y=guessFiles'})]}}]}
    
end
