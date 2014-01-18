class E

  F['/search.n3/GET'] = F['/search/GET']

  fn 'view/'+Search,-> d,e {
    [H.css('/css/search'),H.js('/js/search'),
     {:class => :form,
      c: {_: :form, action: '/search',
         c: {_: :input, name: :q}, # search box
       }}]}

end
