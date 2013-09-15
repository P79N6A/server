watch __FILE__
class E

  fn 'view/edit',->g,e{
    [(H.once e, 'edit', (H.css '/css/edit')),
     g.map{|uri,s|
       {class: :resource,
         c: [{_: :a, class: :uri, id: uri, c: uri, href: s.url},
             s.map{|p,o|
              {property: p, c: p}
             }]}}]}

  fn 'view/edit/html',->g,env{
     {_: :form, name: :editor, c: 'edit'}
  }

end
