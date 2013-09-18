watch __FILE__
class E

  # the editable graph on FS triplestore
  fn 'graph/editable',->resource,env,graph{
    # minimum graph so request reaches edit-view even if resource is empty
    Fn 'graph/_',resource,env,graph
    # current resource state
    resource.fromStream graph, :triplrFsStore}

  fn 'view/edit',->g,e{
    puts "edit #{g.keys}"
    [(H.once e, 'edit', (H.css '/css/edit')),
     g.map{|uri,s| uri &&
       {class: :resource,
         c: [{_: :a, class: :uri, id: uri, c: uri, href: s.url},
             s.map{|p,o|
              {class: :property,
                 c: [{_: :a, class: :uri, c: p, href: p},
                     {_: :a, class: :edit, c: :edit, href: e['REQUEST_PATH']+'?graph=editable&filter=p&view=edit/form&p=uri,'+CGI.escape(p)},
                     (case p
                      when 'uri'
                      when Content
                        {_: :pre, c: o}
                      else
                        o.html
                      end
                      )]}}]}}]}

  fn 'view/edit/form',->g,env{
     {_: :form,
      name: :editor,
      c: g.map{|uri,s|
        s.map{|p,os|
          os.map{|o|
            ['<br>',p,'<br>',
             {_: :input, name: p, value: o}]}}}}}

end
