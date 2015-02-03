# coding: utf-8
#watch __FILE__
class R
 
  Creatable = [
    SIOC+'Forum',
    SIOCt+'BlogPost',
    SIOCt+'Wiki',
    SIOCt+'WikiArticle',
  ]

  ViewGroup['#untyped'] = -> graph, e {
    Creatable.map{|c|
      {_: :a, style: 'font-size: 2em; display:block', c: c.R.fragment, href: e['REQUEST_PATH']+'?new&type='+c.shorten}}}

  ViewGroup['#editable'] = -> graph, e {
    subject = graph.keys[0]
    model = graph[subject] || {'uri' => subject}
    e.q['type'].do{|t|
      model[Type] = t.expand.R}
    model[Title] ||= ''
    model[Content] ||= ''
    [H.css('/css/html'), H.css('/css/wiki'), # View
     {_: :form, method: :POST,
       c: [{_: :table, class: :html,
             c: [{_: :tr, c: {_: :td, colspan: 2,
                     c: [{_: :a, class: :uri, c: subject, href: subject},
                         {_: :a, class: :history, c: 'history', href: R[subject].fragmentPath + '?set=page'}
                        ]}},
                 model.keys.map{|p|
                   {_: :tr,
                     c: [{_: :td, class: :key, c: {_: :a, href: p, c: p.R.abbr}},
                         {_: :td, c: model[p].do{|o|
                             o.justArray.map{|o|
                               case p
                               when 'uri'
                                  [{_: :input, type: :hidden,  name: :uri, value: o}, o.R.href]
                               when Type
                                 unless ['#editable', Directory].member?(o.uri)
                                   [{_: :input, type: :hidden,  name: Type, value: o.uri}, o.R.href]
                                 end
                               when Content
                                 {_: :textarea, name: p, c: o, rows: 16, cols: 80}
                               when Date
                                 {_: :b, c: [o,' ']}
                               when Size
                                 [o,' ']
                               else
                                 {_: :input, name: p, value: o.respond_to?(:uri) ? o.uri : o, size: 54}
                               end }}}].cr}}].cr},
           {_: :a, class: :cancel, href: e.uri, c: 'X'},
           {_: :input, type: :submit, value: 'write'}].cr}]}

  ViewA[SIOCt+'WikiArticle'] = -> r,e {
    [{_: :a, href: r.uri, c: {_: :h1, c: r[Title]}},
     {_: :a, href: r.R.docroot +  '?type=sioct:WikiArticleSection',
      c: [{class: :icon, c: '+'}, ' add section'], class: :create, title: 'add section'}]}

  ViewGroup[SIOCt+'WikiArticle'] = -> g,e {
    [H.css('/css/wiki'),
     g.map{|u,r|
       ViewA[SIOCt+'WikiArticle'][r,e]}]}

 ViewA[SIOCt+'WikiArticleSection'] = -> r,e {
    {class: :section,
     c: [{_: :a, href: r.uri, c: {_: :h2, c: r[Title]}},
         {_: :a, href: r.R.docroot +  '?fragment=' + r.R.fragment, class: :edit, c: :edit},
         r[Content]]}}

end
