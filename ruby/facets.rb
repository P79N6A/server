#watch __FILE__
class R
=begin
   faceted-filter, implemented via dynamically-generated style-sheets
   query-string:
     fv = (name)  render singleton-resource w/ itemview lambda
=end

  fn 'facets',->a,m,e{
    # facets
    a = Hash[(a.split ',').map{|a|[a,{}]}]

    # facet stats
    m.map{|s,r| a.map{|p,_|
        r[p].do{|o|
            o.justArray.map{|o|
            a[p][o]=(a[p][o]||0)+1}}}}


    # facet identifiers
    i={};         c=-1
    n=->o{ 
      i[o]||='f'+(c+=1).to_s}

    view = e.q['fv'].do{|fv| F['itemview/'+fv] } || ->r,e{
      {_: :a, class: :title, href: r.R.url, c: r[Title] || r.uri.abbrURI} if (r.class == R || r.class == Hash) && r.uri}

    resources=->{
      m.map{|u,r| # each resource
        a.map{|p,_| # each facet
          [n[p], r[p].do{|o| # value
               o.justArray.map{|o|
               n[o.to_s] # identifier
             }}].join ' '
        }.do{|f|
          [f.map{|o|'<div class="'+o+'">'}, # facet wrapper
           view[r,e], # resource
           (0..f.size-1).map{|c|'</div>'}]}}}

    [(H.css'/css/facets'),(H.js'/js/facets'),(H.js'/js/mu'),

     a.map{|b,_|{_: :style, class: n[b]}},
     '&nbsp;' * 22,
     a.map{|f,v|{class: :selector, facet: n[f], c: f.label}},

     # facet selection
     {class: :sidebar, c: a.map{|f,v|
         {class: :facet, facet: n[f], # predicate
           c: [{class: :predicate, c: f.label},
               v.sort_by{|k,v|v}.reverse.map{|k,v| # sort by popularity
                 k.respond_to?(:label) &&
                 {facet: n.(k.to_s), # predicate-object tuple
                   c: [{_: :span, class: :count, c: v},
                       {_: :span, class: :name, c: k.label}]}}]}}},     
     (e.q['fv'].do{|fv|F['baseview/'+fv]} || ->m,e,r{r.()}).(m,e,resources)]}
  
  fn 'view/facetSelect',->m,e{
    [(H.js '/js/facets.select'),(H.js '/js/mu'),(H.css '/css/facets'),
     R.graphProperties(m).map{|e|[{c: e},' ']},
     {_: 'button', c: 'Go'}]}

  fn 'view/facets',->m,e{
    e.q['a'].do{|a|F['facets'][a,m,e]} ||
    F['view/facetSelect'][m,e]}

end
