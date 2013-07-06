#watch __FILE__
class E
  fn 'filter/map',->o,m,_{
    o.except('filter','graph','view').map{|p,n|
     p=p.expand
     n=n.expand
      p!=n &&
      m.values.map{|r|
        r[p].do{|o|
          r[n]=o
          r.delete p }}}}

  fn 'view/map',->d,e{
    [H.js('/js/normal'),(H.once e,:mu,(H.js '/js/mu')),
'<style>.b {display:inline-block;font-weight:bold;padding-right:.8em;text-align:right;min-width:12em}
        .exerpt {display:inline-block;max-height:1em;overflow:hidden;max-width:44em;font-size: .9em} </style>',
     {_: :form, c:
      [d.values.map(&:keys).flatten.uniq.-(['uri']).do{|ps|
        ps.map{|p|
           [{class: :b, c: p},{_: :select, name: p, c: 
            (ps + [Date,Creator,Content,Title]).map{|q|
              {_: :option, c: q}.
                  update(p==q ? {selected: :selected}:{})}},
              {class: :exerpt, c: d.values.map{|r|r[p]}.flatten.uniq.html},
              '<br>']}},
       {_: :input, type: :hidden, name: :view, value: :tab},
       {_: :input, type: :hidden, name: :filter, value: :map},
       {_: :input, type: :submit}
       ]}]}

end
