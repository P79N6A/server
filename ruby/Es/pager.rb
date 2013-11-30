#watch __FILE__
class E
  
  Next = LDP+'nextPage'
  Prev = LDP+'prevPage'

  fn 'head/page',->d,e{
    v = e.q['v']
    unless v == 'page'
      h = F['head/'+v] || F['head'] 
      h[d,e]
    end}

  fn 'view/page',->d,e{
    # try daydirs if no pagination data provided
    !d.has_any_key(%w{next prev}) &&
    e['REQUEST_PATH'].match(/(.*?\/)([0-9]{4})\/([0-9]{2})\/([0-9]{2})(.*)/).do{|m|
      t = ::Date.parse "#{m[2]}-#{m[3]}-#{m[4]}"
      d[Prev] = {'uri' => Prev, 'url' => m[1]+(t-1).strftime('%Y/%m/%d')+m[5]}
      d[Next] = {'uri' => Next, 'url' => m[1]+(t+1).strftime('%Y/%m/%d')+m[5]}}

    # links
    c=[d[Prev].do{|p| d.delete('prev') # prev
         {_: :a, rel: :prev, style: 'float:left; font-size:2em',
           href: [*p['url']][0]+e.q.merge(p).except('uri','url').qs,
           title: (p['b']||p['url']), c: '&larr;'}},

       d[Next].do{|n| d.delete('next') # next
         {_: :a, rel: :next, style: 'float:right;font-size:2em',
           href: [*n['url']][0]+e.q.merge(n).except('uri','url').qs, 
           title: (n['b']||n['url']), c: '&rarr;'}}]

    [(H.js '/js/pager'),(H.once e,:mu,(H.js '/js/mu')), # n/p key shortcuts
     c,(H (F['view/'+e.q['v']]||F['view']).(d,e)),      # content
     '<br clear=all>',{class: :bottom, c: c}]}
  
end
