#watch __FILE__
class E

  fn 'view/'+HTTP+'Response',->d,e{
    u = d['#']
    [u[Prev].do{|p|{_: :a, rel: :prev, style: 'background-color:white;color:black;font-size:2.3em;float: left;clear:both',href: p.uri, c: '&larr;'}},
     u[Next].do{|n|{_: :a, rel: :next, style: 'background-color:black;color:white;font-size:2.3em;float:right;clear:both',href: n.uri, c: '&rarr;'}},
     {_: :a, href: e['uri'].E.docBase.a('.n3?')+e['QUERY_STRING'],
       c: {_: :img, src: '/css/misc/cube.png', style: 'height:2em;background-color:white;padding:.54em;border-radius:1em;margin:.2em'}},
     (H.js '/js/pager'),(H.once e,:mu,(H.js '/js/mu')) # n/p key mapping
    ]}

end
