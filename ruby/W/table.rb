#watch __FILE__
class E
  
  # property selector toolbar
  fn 'view/p',->d,e{
    [H.once(e,'property.toolbar',H.once(e,'p',(H.once e,:mu,H.js('/js/mu')),
     H.js('/js/p'),
     H.css('/css/table')),
     {_: :a, href: '#', c: '-', id: :hideP},
     {_: :a, href: '#', c: '+', id: :showP},
     {_: :span, id: 'properties',
       c: E.graphProperties(d).map{|k|
         {_: :a, class: :n, href: k, c: k.label+' '}}},
       {_: :style, id: :pS},
       {_: :style, id: :lS}),
     (Fn 'view/'+(e.q['pv']||'tab'),d,e)]}

  # table layout, sparse matrix of rows/cols - see cal.rb for usage
  fn 'view/t',->d,e,l=nil,a=nil{
    [H.once(e,'table',H.css('/css/table')),
     {_: :table, c:
     {_: :tbody, c: (Fn 'table/'+(l||e.q['table']),d).do{|t|
          rx = t.keys.max
          rm = t.keys.min
          c = t.values.map(&:keys)
          cm = c.map(&:min).min
          cx = c.map(&:max).max
          (rm..rx).map{|r|
            {_: :tr, c: 
              t[r].do{|r|
                (cm..cx).map{|c|
                  r[c].do{|c|
                    {_: :td, class: :cell, c:(Fn 'view/'+(a||e.q['cellview']),c,e)}
                    }||{_: :td}}}}}}}}]}

# a simple tabular view
  fn 'view/table',->i,e{
    [H.css('/css/table'),
     (Fn 'table',i.values,e)]}

  F['view/tab']=F['view/table']

  fn 'table',->es,q=nil{
    ks = {}
    es.map{|e|e.respond_to?(:keys) && e.keys.map{|k|ks[k]=true}}
    keys = ks.keys - ['uri']
    keys.empty? ? (es.html false) :
    H({_: :table,:class => :tab,
        c: [{_: :tr,
              c: [{_: :td},
                  *keys.map{|k|
                    {_: :td, class: :label,
                      c: q ? {_: :a,
                        href: q['REQUEST_PATH']+q.q.except('reverse').merge({sort: k}).merge(q.q.member?('reverse') ? {} : {'reverse'=>true}).qs,
                        c: (Fn 'abbrURI',k)} : k}}]},
            *es.map{|e|
              {_: :tr, about: e.uri, c:
                [{_: :td, property: :uri,
                   c: e['uri'].do{|e|e.E.html}},
                 *keys.map{|k|
                   {_: :td, property: k, c: e[k].do{|v|
                       (v.class==Array ? v : [v]).map(&:html).join ' '}}}]}}]})}

  fn 'table/elements',->d{ m={}
    g='t:group'.expand
    p='t:period'.expand
    d.map{|u,r|
      r[g].do{|g|   g = g[0].uri.match(/[0-9]+$/)
        r[p].do{|p| p = p[0].uri.match(/[0-9]+$/)
          g && p &&
          (g = g[0].to_i
           p = p[0].to_i
           m[p]     ||= {}
           m[p][g]  ||= {}
           m[p][g][u] = r
           )}}}
    m}

  F["?"]||={}
  F["?"].update({'elements'=>{'view' => 'p','pv' => 't','table' => 'elements', 'cellview' => 'element'}})

 # element
  fn 'view/element',->d,e{
    l = d[d.keys[0]]
    [H.once(e,'elements.css',H.css('/css/elements')),
     {class: l[Abbrev['t']+'classification'].do{|p|p[0].uri.label},
       c: [l[Abbrev['t']+'symbol'],(Fn 'view',d,e)]}]}
  
end
