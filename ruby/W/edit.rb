watch __FILE__
class E

  fn 'view/edit',->g,e{
    [(H.once e, 'edit', (H.css '/css/edit')),
     g.map{|uri,s|
       {class: :resource,
         c: [{_: :a, class: :uri, id: uri, c: uri, href: s.url},
             s.map{|p,o|
              {class: :property,
                 c: [{_: :a, class: :uri, c: p, href: p},
                     {_: :span, class: :edit, c: :edit},
                     (case p
                      when 'uri'
                        #                       uri
                      when Content
                        {_: :pre, c: o}
                      else
                        o.html
                      end
                      )]}}]}}]}

  fn 'view/edit/html',->g,env{
     {_: :form, name: :editor, c: 'edit'}
  }

end
