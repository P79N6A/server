watch __FILE__
class E

  # editable graph on FS triplestore
  fn 'graph/editable',->resource,env,graph{
    # minimum graph
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
            nocache: :true,
               view: :editPO}.map{|n,v|
           {_: :input, type: :hidden, name: n, value: v}},

           # submit
           {_: :input, type: :submit, value: 'property'},
          ]},
     # schema search-engine
     #{_: :iframe, style: 'width: 100%;height:42ex', src: 'http://data.whats-your.name'}
    ]}

  # edit all triples in (s p _)
  fn 'view/editPO',->g,e{

    # subject URI
    s = e['uri']

    # predicate URI
    p = e.q['p'].expand

    # single-triple
    triple = ->s,p,o{

      # triple identifier
      i = (s.E.concatURI p).concatURI E(p).literal o

      ['<br><span class=tripleURI>',CGI.escapeHTML(i.to_s),'</span><br>',
       (case p
        when Content
          {_: :textarea, name: i, c: o, rows: 24, cols: 80}
        else
          {_: :input, name: i, value: o}
        end
        )]}

    {_: :form, name: :editor, method: :POST, action: e['REQUEST_PATH'],
      c: [(H.once e, 'edit', (H.css '/css/edit')),
          s,' &rarr; ',p,
          g.map{|uri,s|
            s[p].map{|o|
              triple[s,p,o]}},
          triple[s,p,''],' ',
          {_: :input, type: :submit, value: 'save'},
          {_: :a, c: ' cancel', href: e['REQUEST_PATH']+'?view=edit&graph=editable&nocache'}
         ]}}

end
