watch __FILE__
class E

  fn 'view/'+HTTP+'Response',->d,e{
    u = d[''] || {}
    {style: "float:left",
      c: [u[Prev].do{|p|{_: :a, rel: :prev, style: 'background-color:white;color:black;font-size:2.3em',href: p.uri, c: '&larr;'}},
          u[Next].do{|n|{_: :a, rel: :next, style: 'background-color:black;color:white;font-size:2.3em',href: n.uri, c: '&rarr;'}},'<br>',
          u[DC+'hasFormat'].do{|fs|
            fs.map{|f|
              [{_: :a, href: f,
                c: (f.uri.match(/n3$/) ? {_: :img, src: '/css/misc/cube.png', style: 'height:2em', alt: :n3, title: :n3} :
                    {style: 'background-color:white;color:#888;display:inline;padding:.2em', c: f.label.split('%')[0]})},'<br>']}},
          (H.js '/js/pager'),(H.once e,:mu,(H.js '/js/mu')) # n/p key mapping
         ]}}

end
