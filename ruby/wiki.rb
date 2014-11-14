#watch __FILE__
class R

  Predicates = {
    SIOC+'Forum' => [Title],
    SIOCt+'MicroblogPost' => [Content],
    SIOCt+'BlogPost' => [Title, Content],
    SIOCt+'BoardPost' => [Title, Content],
    SIOCt+'WikiArticle' => [Title],
    SIOCt+'WikiArticleSection' => [Title, Content],
  }

  View['new'] = -> graph, e {
    Predicates.keys.map{|p|
      {_: :a, style: 'font-size: 2em; display:block', c: p.R.fragment, href: e['REQUEST_PATH']+'?new&view=edit&type='+p.shorten}}}

  View['edit'] = -> graph, e { # edit resource in a <form>

    fragment = e.q['fragment'].do{|s|s.slugify} || '' # fragment-id
    subject = s = e.uri + '#' + fragment              # URI
    model = graph[subject] || {'uri' => subject}      # resource state

    type = model[Type].do{|t|t[0].uri} ||             # bind resource-type
           e.q['type'].do{|t|t.expand} ||
           SIOCt+'WikiArticle'

    Predicates[type].do{|ps| # suggested predicates
      ps.map{|p| model[p] ||= p == Title ? e.R.basename : "" }}

    [H.css('/css/html'), H.css('/css/wiki'), # View
     {_: :form, name: :editor, method: :POST, action: e['REQUEST_PATH'],
       c: [{_: :table, class: :html,
             c: [{_: :tr, c: {_: :td, colspan: 2,
                     c: [{_: :a, class: :uri, c: s, href: s},
                         {_: :a, class: :history, c: 'history', href: R[s].fragmentPath + '?set=page&view=table&empty'}
                        ]}},
                 model.keys.-(['uri',Type]).map{|p|
                   {_: :tr,
                     c: [{_: :td, class: :key, c: {_: :a, href: p, c: p.R.abbr}},
                         {_: :td, c: model[p].do{|o|
                             o.justArray.map{|o|
                               case p
                               when Content
                                 {_: :textarea, name: p, c: o, rows: 16, cols: 80}
                               when Date
                                 {_: :input, name: p, type: :datetime, value: !o || o.empty? && Time.now.iso8601 || o}
                               else
                                 {_: :input, name: p, value: o.respond_to?(:uri) ? o.uri : o, size: 54}
                               end }}}].cr}}].cr},
           {_: :input, type: :hidden, name: Type, value: type},
           {_: :input, type: :hidden, name: :fragment, value: fragment},
           {_: :input, type: :submit, value: 'write'}]}]}

  ViewA[SIOCt+'WikiArticle'] = -> r,e {
    [{_: :a, href: r.uri, c: {_: :h1, c: r[Title]}},
     {_: :a, href: r.R.docroot +  '?type=sioct:WikiArticleSection&view=edit',
      c: [{class: :icon, c: '+'}, ' add section'], class: :create, title: 'add section'},
     H.once(e,:wiki,H.css('/css/wiki'))]}

  ViewA[SIOCt+'WikiArticleSection'] = -> r,e {
    {class: :section,
     c: [{_: :a, href: r.uri, c: {_: :h2, c: r[Title]}},
         {_: :a, href: r.R.docroot +  '?view=edit&fragment=' + r.R.fragment, class: :edit, c: :edit},
         r[Content],
         H.once(e,:wiki,H.css('/css/wiki'))]}}

end
