watch __FILE__
%w{exhibit hist normal protovis sw time timeline}.each{|e|require 'element/W/examine/'+e}
class E

  fn 'view/examine',->a,m,e{
    a=Hash[(a.split ',').map{|a|[a,{}]}] # facets

    # facet stats
    m.map{|s,r| a.map{|p,_|
        r[p].do{|o|
          (o.class==Array ? o : [o]).map{|o|
            a[p][o]=(a[p][o]||0)+1}}}}


    # facet identifiers
    i={};         c=-1
    n=->o{
      i[o]||='f'+(c+=1).to_s}

    view=F['view/'+ (e.q['ev'] || 'divine') + '/item']

    resources=->{
      m.map{|u,r| # each resource
        a.map{|p,_| # each facet
          [n.(p),r[p].do{|o| # value
             (o.class==Array ? o : [o]).map{|o|
               n.(o.to_s) # identifier
             }}].join ' '
        }.do{|f|
          [f.map{|o|'<div class="'+o+'">'}, # facet wrapper
           view.(r,e), # resource
           (0..f.size-1).map{|c|'</div>'}]}}}

    [(H.css'/css/examine'),(H.js'/js/examine'),(H.js'/js/mu'),

     a.map{|b,_|{_: :style, class: n.(b)}},

     # facet sidebar
     {class: :sidebar, c: a.map{|f,v|
         {class: :facet, title: f, facet: n.(f),
           c: [f.label,
               v.sort_by{|k,v|v}.reverse.map{|k,v|
                 k.respond_to?(:label) &&
                 {f: n.(k.to_s),
                   c: [{class: :count, c: v},
                       {_: :span, class: :name, c: k.label}]}}]}}},
     
     (F['view/'+e.q['ev']+'/base']||
      ->m,e,r{r.()}).(m,e,resources)]}
  
  fn 'view/examine/selectFacets',->m,e{
    [(H.js '/js/examine.selectFacet'),(H.js '/js/mu'),(H.css '/css/examine'),
     E.graphProperties(m).map{|e|[{c: e},' ']},
     {_: 'button', c: 'Go'}]}

  fn 'view/e',->m,e{
    e.q['a'].do{|a|Fn 'view/examine',a,m,e} || 
                  (Fn 'view/examine/selectFacets',m,e)}
end
