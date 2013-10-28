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

  # table layout, sparse matrix of rows/columns
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
    ks = {} # predicate table
    es.map{|e|e.respond_to?(:keys) &&
              e.keys.map{|k|ks[k]=true}}
    keys = ks.keys
    keys.empty? ? es.html :
    H({_: :table,:class => :tab,
        c: [{_: :tr,
              c: keys.map{|k|
                {_: :td, class: :label, property: k,
                  c: q ? {_: :a,
                    href: q['REQUEST_PATH']+q.q.except('reverse').merge({'sort'=>k}).merge(q.q.member?('reverse') ? {} : {'reverse'=>true}).qs,
                    c: (Fn 'abbrURI',k)} : k}}},
            *es.map{|e|
              {_: :tr, about: e.uri, c:
                keys.map{|k|
                  {_: :td, property: k, c: e[k].do{|v|
                      (v.class==Array ? v : [v]).map(&:html).join ' '}}}}}]})}

end
