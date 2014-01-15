class E
  
  fn '/search/GET',->e,r{
    r.q['graph'] = 'roonga'
    e.response }

  F['/search.n3/GET'] = F['/search/GET']

  fn 'view/'+Search,-> d,e {
    [H.css('/css/search'),H.js('/js/search'),
     {:class => :form,
      c: {_: :form, action: '/search',
        c: [{_: :input, name: :q, value: e.q['q']}, # search box
            e.q.except('q','start'). # new query & offset for this search
            map{|a,s|
              {_: :input, name:  a, value: s, :type => :hidden}}]}}]}

end
