class E
  
  fn '/search/GET',->e,r{
    r.q['graph'] = 'roonga'
    e.response
  }

  fn 'head/search',->d,e{[{_: :title, c: e.q['q']},(Fn 'head.formats',e)]}

  fn 'view/search',->d,e{
    [(Fn 'view/search/form',e.q,e),
     (Fn 'view/page',d,e)]}

  fn 'view/search/form',-> q=nil,e { q||={}
    [H.css('/css/search'),H.js('/js/search'),
     {:class => :form,
      c: {_: :form, action: e['REQUEST_PATH'],
        c: [{_: :input, name: :q, value: q['q']}, # search box
            q.except('q','start'). # new query & offset for this search
            map{|a,s|
              {_: :input, name:  a, value: s, :type => :hidden}}]}},
     {class: :space}]}

end
