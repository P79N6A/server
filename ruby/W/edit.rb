watch __FILE__
class E

  # the editable graph on FS triplestore
  fn 'graph/editable',->resource,env,graph{
    # minimum graph so request reaches edit-view even if resource is empty
    Fn 'graph/_',resource,env,graph
    # current editable graph
    resource.fromStream graph, :triplrFsStore}

  fn 'view/editor/html',->g,e{
    [(H.once e, 'edit', (H.css '/css/edit')),
     g.map{|uri,s| uri && s &&
       (url = uri.E.url
       {class: :resource,
         c: [{_: :a, class: :uri, id: uri, c: uri, href: url, title: 'view '+uri},
             {_: :a, class: :addField, c: '+add field', href: url+'?graph=_&view=editor/html/addField&nocache'},
             s.map{|p,o|
              {class: :property,
                 c: [{_: :a, class: :edit, c: :edit, href: e['REQUEST_PATH']+'?graph=editable&filter=p&nocache&view=editor/html/form&p=uri,'+CGI.escape(p)},
                     (case p
                      when 'uri'
                        {_: :a, class: :uri, c: p, href: p}
                      when Content
                        {_: :pre, c: o}
                      else
                        o.html
                      end)]}}]})}]}

  # paramaterize field-edit view w/ a property URI
  fn 'view/editor/html/addField',->g,env{
    [# display core properties
     [Date,Title,Creator,Content,Label].map{|p|
       {_: :a, href: p, c: p.label+' '}
     },
     # input area
     {_: :form, action: env['REQUEST_PATH'], method: :GET,
       c: [{_: :input, type: :url, name: :p, pattern: '^http.*$', size: 53},
           {_: :input, type: :hidden, name: :view, value: 'editor/html/form'},
           {_: :input, type: :hidden, name: :filter, value: :p},
           {_: :input, type: :hidden, name: :graph, value: :editable},
           {_: :input, type: :submit, value: 'add property'},
          ]},'<br>',
     # schema search-engine (optimize and move to localhost w/ 1 JSON file in git?)
     {_: :iframe, style: 'width: 100%;height:42ex', src: 'http://data.whats-your.name'}]
  }

  fn 'view/editor/html/form',->g,env{
     {_: :form, name: :editor,
      c: g.map{|uri,s|
        s[p].map{|oArray|
          oArray.map{|o|
            ['<br>',p,'<br>',
             {_: :input, name: p, value: o}]}}}}}

end
