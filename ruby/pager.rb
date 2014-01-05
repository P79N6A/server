watch __FILE__
class E
  
  Next = LDP+'nextPage'
  Prev = LDP+'prevPage'

  fn 'head/page',->d,e{v=e.q['v']
    u = d['#'] ||= {}
    # head of wrapped view
    [((v && F['head/'+v] || F['head'])[d,e] unless v == 'page'),
     u[Next].do{|n|{_: :link, rel: :next, href: n.uri}},
     u[Prev].do{|p|{_: :link, rel: :prev, href: p.uri}}]}

  fn 'view/'+LDP+'container',->d,e{
    {style: "background-color:white;color:black;border-radius:.6em;float:left",
      c: [{_: :b, style: 'font-size:2em;color:#22f',c: '*'},
          d['#'].do{|s|s[DC+'hasFormat'].do{|fs|fs.map{|f|{_: :a, href: f, c: f.label}}}}]}}
  
  fn 'view/page',->d,e{
    u = d['#'] ||= {}

    # links
    c=[u[Prev].do{|p|
         {_: :a, rel: :prev, style: 'float:left; font-size:2em',href: p.uri, c: '&larr;'}},
       u[Next].do{|n|
         {_: :a, rel: :next, style: 'float:right;font-size:2em',href: n.uri, c: '&rarr;'}}]

    [(H.js '/js/pager'),(H.once e,:mu,(H.js '/js/mu')),c,
     (e.q['v'].do{|v|F['view/'+v]} || F['view'])[d,e],
     {class: :bottom, style: "clear:both", c: c}]}
  
end
