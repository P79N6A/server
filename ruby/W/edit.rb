watch __FILE__
class E

  # the editable graph on FS triplestore
  fn 'graph/editable',->resource,env,graph{
    # minimum graph so request reaches edit-view even if resource is empty
    Fn 'graph/_',resource,env,graph
    # current editable graph
    resource.fromStream graph, :triplrFsStore}

  # show resource w/ links into editor
  fn 'view/edit',->g,e{
    [(H.once e, 'edit', (H.css '/css/edit')),
     g.map{|uri,s| uri && s &&
       (url = uri.E.url
       {class: :resource,
         c: [{_: :a, class: :uri, id: uri, c: uri, href: url, title: 'view '+uri},
             {_: :a, class: :addField, c: '+add field', href: url+'?graph=_&view=editP&nocache'},
             s.map{|p,o|
              {class: :property,
                 c: [{_: :a, class: :edit, c: :edit, href: e['REQUEST_PATH']+'?graph=editable&filter=p&nocache&view=editPO&p=uri,'+CGI.escape(p)},
                     (case p
                      when 'uri'
                        {_: :a, class: :uri, c: p, href: p}
                      when Content
                        {_: :pre, c: o}
                      else
                        o.html
                      end)]}}]})}]}

  # select or mint a property to edit
  fn 'view/editP',->g,env{
    [# convenience ubiquitous properties
     [Date,Title,Creator,Content,Label].map{|p|
       {_: :a, href: p, c: p.label+' '}},
     # URI-constrained input
     {_: :form, action: env['REQUEST_PATH'], method: :GET,
       c: [{_: :input, type: :url, name: :p, pattern: '^http.*$', size: 53},
           # edit view arguments
           {filter: :p, graph: :editable,
             nocache: :true, view: :editPO}.map{|n,v|
           {_: :input, type: :hidden, name: n, value: v}},
           # submit
           {_: :input, type: :submit, value: 'property'},
          ]},
     # schema search-engine
     #{_: :iframe, style: 'width: 100%;height:42ex', src: 'http://data.whats-your.name'}
    ]}

  # editor a specific property (all triple 'objects' in [s p _])
  fn 'view/editPO',->g,e{
    # subject/resource URI
    s = e['uri']
    # predicate/property URI
    p = e.q['p'].expand

    puts "Editing s #{s} p #{p}"

    # each triple has an identifier
    # render a single triple's field
    triple = ->s,p,o{
      ['<br><br>',
       (case p
        when Content
          {_: :textarea, name: p, c: o, rows: 24, cols: 80}
        else
          {_: :input, name: p, value: o}
        end
        )]}

    {_: :form, name: :editor,
      c: [s,' &rarr; ',p,
          g.map{|uri,s|
            s[p].map{|o|
              triple[s,p,o]}},
          triple[s,p,''],' ',
          {_: :input, type: :submit, value: 'save'},
          {_: :a, c: ' cancel', href: e['REQUEST_PATH']+'?view=edit&graph=editable&nocache'}
         ]}}

end
