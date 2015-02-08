# coding: utf-8
#watch __FILE__
class R

  ViewGroup[Wiki] = -> g,e {
    [H.css('/css/wiki'),
     g.values.map{|r|ViewA[Wiki][r,e]}]}

  ViewA[Wiki] = -> r,e {
    {class: :wiki,
     c: [{_: :a, class: :wikiTitle, href: r.uri, c: r[Title]},
         ([{_: :a, class: :edit, href: r.uri + '?edit', c: '✑', title: 'edit Wiki description'},
           {_: :a, class: :addArticle, href: r.uri + '?new', c: [{_: :span, class: :pen, c: "✑"}, "+article"]}] if e.signedIn), '<br>',
         {_: :span, class: :desc, c: r[Content]}]}}

  ViewGroup[SIOCt+'WikiArticle'] = -> g,e {
    [H.css('/css/wiki'),
     g.map{|u,r|
       ViewA[SIOCt+'WikiArticle'][r,e]}]}

  ViewA[SIOCt+'WikiArticle'] = -> r,e {
    doc = r.R.docroot.uri
    [{_: :a, class: :articleTitle, href: r.uri, c: r[Title]},
     ([{_: :a, class: :edit, href: doc + '?edit&fragment=', c: '✑', title: 'edit article description'},
       {_: :a, class: :addSection, href: doc +  '?new&type=sioct:WikiArticleSection', c: '+section', title: 'add section'}] if e.signedIn), '<br>',
     {_: :span, class: :desc, c: r[Content]},
    ]}

  ViewGroup[SIOCt+'WikiArticleSection'] = -> g,e {g.map{|u,r|ViewA[SIOCt+'WikiArticleSection'][r,e]}}

  ViewA[SIOCt+'WikiArticleSection'] = -> r,e {
    {class: :section,
     c: [{_: :a, class: :sectionTitle, href: r.uri, c: r[Title]},'<br>',
         r[Content],
         ({_: :a, href: r.R.docroot +  '?edit&fragment=' + r.R.fragment, class: :edit, c: '✑'} if e.signedIn)]}}

end
