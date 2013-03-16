class E

  fn '/search/GET',->e,r{ E.groonga
    r.q.empty? ? [303,{'Location' => '/search?view=search&v=grep'},[]] :
    (e.resources (E.roonga r).do{|s|
       s.empty? ? {'search' => E('/search')} : s})}
  
  fn 'head/search',->d,e{[{_: :title, c: e.q['q']},(Fn 'head.formats',e)]}

  fn 'view/search',->d,e{
    [H.css('/css/search'),H.js('/js/search'),
     (Fn 'view/search/form',e.q),'<br><br>',
     (Fn 'view/page',d,e)]}

  fn 'view/search/form',-> q=nil { q||={}
    {:class => :form,
      c: {_: :form, action: '/search',
        c: [{_: :input, name: :q, value: q['q']},
            q.update(q['view'] ? {} : {'view' => 'search'}).except('q','start').map{|a,s|
              {_: :input, name:  a, value: s, :type => :hidden}}]}}}

end
