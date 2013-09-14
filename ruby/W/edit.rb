watch __FILE__
class E

  fn 'view/edit',->g,e{
    [(H.once e, 'edit', (H.css '/css/edit')),
     g.map{|u,r|
       {class: :resource,
         id: u,
         c: [{_: :a, class: :uri, c: u, href: r.url}]}}]}

  fn 'view/editor',->g,env{
     {_: :form, name: :editor, c: 'edit'}
  }

end
