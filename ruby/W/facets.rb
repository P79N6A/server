watch __FILE__
class E

  fn 'view/facets/main',->a,m,e{
    # facets
    a = Hash[(a.split ',').map{|a|[a,{}]}]

    # facet stats
    m.map{|s,r| a.map{|p,_|
        r[p].do{|o|
          (o.class==Array ? o : [o]).map{|o|
            a[p][o]=(a[p][o]||0)+1}}}}


    # facet identifiers
    i={};         c=-1
    n=->o{ 
      i[o]||='f'+(c+=1).to_s}

    view=F['view/'+ (e.q['fv'] || 'divine') + '/item']
    resources=->{
      m.map{|u,r| # each resource
        a.map{|p,_| # each facet
          [n[p], r[p].do{|o| # value
             (o.class==Array ? o : [o]).map{|o|
               n[o.to_s] # identifier
             }}].join ' '
        }.do{|f|
          [f.map{|o|'<div class="'+o+'">'}, # facet wrapper
           view[r,e], # resource
           (0..f.size-1).map{|c|'</div>'}]}}}

    [(H.css'/css/facets'),(H.js'/js/facets'),(H.js'/js/mu'),

     a.map{|b,_|{_: :style, class: n[b]}},

     # facet selection
     {class: :sidebar, c: a.map{|f,v|
         {class: :facet, title: f, facet: n[f], # predicate
           c: [f.label,
               v.sort_by{|k,v|v}.reverse.map{|k,v| # sort by popularity
                 k.respond_to?(:label) &&
                 {facet: n.(k.to_s), # predicate-object tuple
                   c: [{_: :span, class: :count, c: v},
                       {_: :span, class: :name, c: k.label}]}}]}}},
     
     (F['view/'+e.q['fv']+'/base']||
      ->m,e,r{r.()}).(m,e,resources)]}
  
  fn 'view/facets/select',->m,e{
    [(H.js '/js/facets.select'),(H.js '/js/mu'),(H.css '/css/facets'),
     E.graphProperties(m).map{|e|[{c: e},' ']},
     {_: 'button', c: 'Go'}]}

  fn 'view/facets',->m,e{
    e.q['a'].do{|a|Fn 'view/facets/main',a,m,e} || 
                  (Fn 'view/facets/select',m,e)}

end
