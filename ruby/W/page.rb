watch __FILE__
class E
  
  fn 'head/page',->d,e{
    v = e.q['v']
    Fn 'head' + (v != 'page' && '/' + v), d, e}

  fn 'view/page',->d,e{
    puts e['REQUEST_PATH'],'l' 	
    c={style: 'width:100%;display:block;clear:both',
      c: [d['prev'].do{|p| d.delete('prev')
            {_: :a,
              rel: :prev, style: 'float:left; font-size:2em',
              href: [*p['url']][0]+e.q.merge(p).except('uri','url').qs,
              title: (p['b']||p['url']),
              c: '&larr;'}},
          d['next'].do{|n| d.delete('next')
            {_: :a,
              rel: :next, style: 'float:right;font-size:2em',
              href: [*n['url']][0]+e.q.merge(n).except('uri','url').qs, 
              title: (n['b']||n['url']),
              c: '&rarr;'}}]}

    [(H.js '/js/pager'),(H.once e,:mu,(H.js '/js/mu')),
     c,
     (H (F['view/'+e.q['v']]||F['view']).(d,e)),
     c]}
  
end
