#watch __FILE__
class E
  
  Next = LDP+'nextPage'
  Prev = LDP+'prevPage'

  fn 'head/page',->d,e{
    v = e.q['v']
    # head of contained view
    [(unless v == 'page'
        h = v && F['head/'+v] || F['head']
        h[d,e]
      end),
     # page links, preserving ambient query-string values
     d[Next].do{|n|{_: :link, rel: :next, href: [*n['url']][0]+e.q.merge(n).except('uri','url').qs}},
     d[Prev].do{|p|{_: :link, rel: :prev, href: [*p['url']][0]+e.q.merge(p).except('uri','url').qs}}]}

  fn 'view/page',->d,e{
    # use daydirs if no pagination data exists
    !d.has_any_key([Next,Prev]) &&
    e['REQUEST_PATH'].match(/(.*?\/)([0-9]{4})\/([0-9]{2})\/([0-9]{2})(.*)/).do{|m|

      t = ::Date.parse "#{m[2]}-#{m[3]}-#{m[4]}"

      pp = m[1] + (t-1).strftime('%Y/%m/%d') + m[5]
      np = m[1] + (t+1).strftime('%Y/%m/%d') + m[5]

      d[Prev] = {'uri' => Prev, 'url' => pp} if pp.E.e || E['http://' + e['SERVER_NAME'] + pp].e
      d[Next] = {'uri' => Next, 'url' => np} if np.E.e || E['http://' + e['SERVER_NAME'] + np].e
    }

    # links
    c=[d[Prev].do{|p|
         {_: :a, rel: :prev, style: 'float:left; font-size:2em',
           href: [*p['url']][0]+e.q.merge(p).except('uri','url').qs,
           title: (p['b']||p['url']), c: '&larr;'}},

       d[Next].do{|n|
         {_: :a, rel: :next, style: 'float:right;font-size:2em',
           href: [*n['url']][0]+e.q.merge(n).except('uri','url').qs, 
           title: (n['b']||n['url']), c: '&rarr;'}}]

    [(H.js '/js/pager'),(H.once e,:mu,(H.js '/js/mu')), # n/p key shortcuts
     c,(H (e.q['v'].do{|v|F['view/'+v]} || F['view']).(d,e)),      # content
     '<br clear=all>',{class: :bottom, c: c}]}
  
end
