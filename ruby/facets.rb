class R

  # facet-filtering - dynamic CSS edition

  View['facets'] = -> m,e {
    a = Hash[((e.q['a']||'sioct:ChatChannel').split ',').map{|a|
               [a.expand,{}]}]

    # statistics
    m.map{|s,r| a.map{|p,_|
        r[p].do{|o|
            o.justArray.map{|o|
            a[p][o]=(a[p][o]||0)+1}}}}

    # identifiers
    i = {}
    c = 0
    n = ->o{i[o] ||= 'f'+(c+=1).to_s}
    e[:container] = false
    [(H.css'/css/facets'),(H.js'/js/facets'),(H.js'/js/mu'),

     # facet selection
     {class: :sidebar, c: a.map{|f,v|
         {class: :facet, facet: n[f], # predicate
           c: [{class: :predicate, c: f},
               v.sort_by{|k,v|v}.reverse.map{|k,v| # sort by popularity
                 {facet: n.(k.to_s), # predicate-object tuple
                   c: [{_: :span, class: :count, c: v},
                       {_: :span, class: :name, c: (k.respond_to?(:uri) ? k.R.abbr : k.to_s)}]}}]}}},

     m.map{|u,r| # each resource
       a.map{|p,_| # each facet
         [n[p], r[p].do{|o| # value
            o.justArray.map{|o|
              n[o.to_s] # identifier
            }}].join ' '
       }.do{|f|
         [f.map{|o| '<div class="' + o + '">' }, # open wrapper
          HTMLr[{u => r},e],               # render resource
          (0..f.size-1).map{|c|'</div>'}, "\n",  # close wrapper
         ]}}]}

end
