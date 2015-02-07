# coding: utf-8
watch __FILE__
class R
 
  Creatable = [Forum, Wiki, BlogPost, WikiArticle]

  ViewGroup[Wiki] = -> g,e {
    [H.css('/css/wiki',true),
     g.values.map{|r|ViewA[Wiki][r,e]}]}

  ViewA[Wiki] = -> r,e {
    {class: :wiki,
     c: [{_: :span, class: :wikiTitle, c: r[Title]},
         ([{_: :a, class: :edit, href: r.uri + '?edit', c: '✑', title: 'edit Wiki description'},
           {_: :a, class: :addArticle, href: r.uri + '?new', c: [{_: :span, class: :pen, c: "✑"}, "new article"]}] if e.signedIn), '<br>',
         {_: :span, class: :desc, c: r[Content]}]}}

  ViewGroup[SIOCt+'WikiArticle'] = -> g,e {
    [H.css('/css/wiki'),
     g.map{|u,r|
       ViewA[SIOCt+'WikiArticle'][r,e]}]}

  ViewA[SIOCt+'WikiArticle'] = -> r,e {
    doc = r.R.docroot.uri
    [{_: :a, class: :articleTitle, href: r.uri, c: r[Title]},
    ({_: :a, class: :edit, href: doc + '?edit&fragment=', c: '✑', title: 'edit article description'} if e.signedIn),
     {_: :a, class: :addSection, href: doc +  '?new&type=sioct:WikiArticleSection', c: '+section', title: 'add section'},
     '<br>',
     {_: :span, class: :desc, c: r[Content]},
    ]}

  ViewGroup[SIOCt+'WikiArticleSection'] = -> g,e {
    g.map{|u,r|ViewA[SIOCt+'WikiArticleSection'][r,e]}}

  ViewA[SIOCt+'WikiArticleSection'] = -> r,e {
    {class: :section,
     c: [{_: :a, href: r.uri, c: {_: :h2, c: r[Title]}},
         {_: :a, href: r.R.docroot +  '?edit&fragment=' + r.R.fragment, class: :edit, c: :edit},
         r[Content]]}}

  ViewGroup['#untyped'] = -> graph, e {
    Creatable.map{|c|
      {_: :a, style: 'font-size: 2em; display:block', c: c.R.fragment,
       href: e['REQUEST_PATH']+'?new&type='+c.shorten}}}

  ViewGroup['#editable'] = -> graph, e {
    [graph.map{|u,r|ViewA['#editable'][r,e]},
     H.css('/css/edit'), H.css('/css/html')]}

  ViewA['#editable'] = -> re, e {
    e.q['type'].do{|t|
      re[Type] = t.expand.R}
    re[Title] ||= ''
    re[Content] ||= ''
     {_: :form, method: :POST,
       c: [{_: :table, class: :html,
             c: [{_: :tr, c: {_: :td, colspan: 2,
                     c: {_: :a, class: :uri, c: re.uri, href: re.uri}}},
                 re.keys.map{|p|
                   {_: :tr,
                     c: [{_: :td, class: :key, c: {_: :a, href: p, c: p.R.abbr}},
                         {_: :td, c: re[p].do{|o|
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
           {_: :input, type: :submit, value: 'write'}].cr}}

end
