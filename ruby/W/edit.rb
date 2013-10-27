watch __FILE__
class E

  fn 'protograph/editable',->resource,env,graph{
    Fn 'protograph/_',resource,env,graph}

  fn 'graph/editable',->resource,env,graph{
    resource.fromStream graph, :triplrFsStore}

  # show resource w/ links into editor
  fn 'view/edit',->g,e{
    [(H.once e, 'edit', (H.css '/css/edit')),
     g.map{|uri,s| uri && s &&
       (url = uri.E.localURL e
       {class: :resource,
         c: [{_: :a, class: :uri, id: uri, c: uri, href: url, title: 'view '+uri},
             {_: :a, class: :addField, c: '+add field', href: url+'?graph=_&view=editP'},
             s.map{|p,o|
              {class: :property,
                 c: [{_: :a, class: :edit, c: :edit,
                       href: e['REQUEST_PATH']+'?graph=editable&filter=p&view=editPO&p=uri,'+CGI.escape(p)},
                     (case p
                      when 'uri'
                        {_: :a, class: :uri, c: p, href: p}
                      when Content
                        {_: :pre, c: o}
                      else
                        o.html
                      end)]}}]})}]}

  # select or mint a property to edit
  fn 'view/editP',->g,e{
    [(H.once e, 'edit', (H.css '/css/edit')),

     # core properties
     [Date,Title,Creator,Content,Label].map{|p|
       {_: :a, href: p, c: p.label+' '}},

     # URI-typed input
     {_: :form, action: e['REQUEST_PATH'], method: :GET,
       c: [{_: :input, type: :url, name: :p, pattern: '^http.*$', size: 53},

           # editor arguments
           { filter: :p,
              graph: :editable,
               view: :editPO}.map{|n,v|
           {_: :input, type: :hidden, name: n, value: v}},

           # submit
           {_: :input, type: :submit, value: 'property'},
          ]},
     # schema search-engine
     #{_: :iframe, style: 'width: 100%;height:42ex', src: 'http://data.whats-your.name'}
    ]}

  # edit triples
  fn 'view/editPO',->g,e{

    p = e.q['p'].expand

    # triple -> input
    triple = ->s,p,o{

      # triple identifier
      i = (s.E.concatURI p).concatURI E(p).literal o

      [(case p
        when Content
          {_: :textarea, name: i, c: o, rows: 24, cols: 80}
        else
          {_: :input, name: i, value: o}
        end
        )]}

    {_: :form, name: :editor, method: :POST, action: e['REQUEST_PATH'],
      c: [(H.once e, 'edit', (H.css '/css/edit')),
          {_: :h2, c: p},
          # existing entries
          g.map{|s,r| r[p].do{|p| p.map{|o|
              triple[s,p,o]}.cr}},
          # new entry
          triple[e['uri'],p,''],' ',
          {_: :input, type: :submit, value: 'save'},
          {_: :a, c: ' cancel', href: e['REQUEST_PATH']+'?view=edit&graph=editable'}
         ]}}

end
