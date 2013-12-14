watch __FILE__
class E
  # a HTML <form> approach to RDF editing

  F['protograph/editable'] = F['protograph/_']

  fn 'graph/editable',->e,env,g{
    e.fromStream g, :triplrFsStore}

  fn 'view/edit',->g,e{
    [(H.once e, 'edit', (H.css '/css/edit')),
     g.map{|uri,s| uri && s &&
       (url = uri.E.localURL e
        edit = e['REQUEST_PATH']+'?graph=editable&view=editPO'
       {class: :resource,
         c: [{_: :a, class: :uri, id: uri, c: uri, href: url, title: 'view '+uri},
             {_: :a, class: :edit, c: '+p', href: url+'?graph=_&view=editP'},{_: :a, class: :edit, href: edit,c: :edit},'<br>',
             s.map{|p,o|
              {class: :property,
                 c: [{_: :a, class: :uri, href: edit + '&p=' + CGI.escape(p), title: :edit, c: p},' ',
                     (case p
                      when 'uri'
                        {_: :a, c: p, href: p}
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

    p = e.q['p'].do{|p|p.expand}

    # triple -> <input>
    triple = ->s,p,o{
      id = (s.E.concatURI p).concatURI E(p).literal o
      [(case p
        when Content
          {_: :textarea, name: id, c: o, rows: 24, cols: 80}
        else
          {_: :input, name: id, value: o}
        end
        ),"<br>\n"]}

    {_: :form, name: :editor, method: :POST, action: e['REQUEST_PATH'],
      c: [(H.once e, 'edit', (H.css '/css/edit')),          
          g.map{|s,r|
            (p ? [p] : r.keys).map{|p|
              [{_: :b, c: p},'<br>',
               r[p].do{|os|
                 os.map{|o|triple[s,p,o]}}, # extant
               triple[e['uri'],p,''] # blank
              ]} if r.class == Hash},
          {_: :input, type: :submit, value: 'save'},
          {_: :a, class: :back, c: 'back', href: e['REQUEST_PATH']+'?view=edit&graph=editable'}]}}

end
