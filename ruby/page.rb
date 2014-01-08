watch __FILE__
class E
  
  Next = LDP+'nextPage'
  Prev = LDP+'prevPage'

  fn 'view/'+LDP+'container',->d,e{
    u = d[''] || {}
    {style: "float:left",
      c: [u[Prev].do{|p|{_: :a, rel: :prev, style: 'background-color:white;color:black;font-size:2em',href: p.uri, c: '&larr;'}},
          u[Next].do{|n|{_: :a, rel: :next, style: 'font-size:2em',href: n.uri, c: '&rarr;'}},
          u[DC+'hasFormat'].do{|fs|
            fs.map{|f|
              [{_: :a, href: f,
                c: (f.uri.match(/n3$/) ? {_: :img, src: '/css/misc/cube.png', style: 'height:2em'} :
                    {style: 'background-color:white;color:black;display:inline;padding:.2em', c: f.label.split('%')[0]})},'<br>']}}]}}

end
