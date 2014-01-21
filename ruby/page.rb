#watch __FILE__
class E

  fn 'view/'+HTTP+'Response',->d,e{
    u = d['#']

    [u[Prev].do{|p|
       {_: :a, rel: :prev, href: p.uri, c: '&larr;',
         style: 'color:#ccc;background-color:#eee;font-size:2.3em;float:left;clear:both;margin-right:.3em'}},
     u[Next].do{|n|
       {_: :a, rel: :next, href: n.uri, c: '&rarr;',
         style: 'color:#ccc;background-color:#eee;font-size:2.3em;float:right;clear:both;border-radius:0'}},

     {_: :a, href: e['REQUEST_PATH'].sub(/\.html$/,'') + e.q.merge({'view'=>'data'}).qs, # data browser
       c: {_: :img, src: '/css/misc/cube.png', style: 'height:2em;background-color:white;padding:.54em;border-radius:1em;margin:.2em'}},
     (H.js '/js/pager'),(H.once e,:mu,(H.js '/js/mu')) # (n)ext (p)rev key mappings
    ]}

end
