#watch __FILE__
class E
  
  Next = LDP+'nextPage'
  Prev = LDP+'prevPage'

  fn 'head/page',->d,e{
    v = e.q['v']
    u = d[e['REQUEST_URI']] ||= {}
    # include head/ of wrapped view
    [((v && F['head/'+v] || F['head'])[d,e] unless v == 'page'),
     u[Next].do{|n|{_: :link, rel: :next, href: n.uri}},
     u[Prev].do{|p|{_: :link, rel: :prev, href: p.uri}}]}

  fn 'view/page',->d,e{
    u = d[e['REQUEST_URI']] ||= {}

    # use day-pages if no pagination data exists
    !u.has_any_key([Next,Prev]) &&
    e['REQUEST_PATH'].match(/(.*?\/)([0-9]{4})\/([0-9]{2})\/([0-9]{2})(.*)/).do{|m|

      t = ::Date.parse "#{m[2]}-#{m[3]}-#{m[4]}"
      pp = m[1] + (t-1).strftime('%Y/%m/%d') + m[5]
      np = m[1] + (t+1).strftime('%Y/%m/%d') + m[5]
      u[Prev] = {'uri' => pp + '?view=page'} if pp.E.e || E['http://' + e['SERVER_NAME'] + pp].e
      u[Next] = {'uri' => np + '?view=page'} if np.E.e || E['http://' + e['SERVER_NAME'] + np].e }

    # links
    c=[u[Prev].do{|p|
         {_: :a, rel: :prev, style: 'float:left; font-size:2em',href: p.uri, c: '&larr;'}},
       u[Next].do{|n|
         {_: :a, rel: :next, style: 'float:right;font-size:2em',href: n.uri, c: '&rarr;'}}]

    [(H.js '/js/pager'),(H.once e,:mu,(H.js '/js/mu')),c,
     (e.q['v'].do{|v|F['view/'+v]} || F['view'])[d,e],
     {class: :bottom, style: "clear:both", c: c}]}
  
end
