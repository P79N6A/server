# coding: utf-8
#watch __FILE__
class R

  def buildDoc
    graph = {}
    fragments.map{|f| f.nodeToGraph graph}
    jsonDoc.w graph, true
  end
 
  Creatable = [
    SIOC+'Forum',
    SIOCt+'MicroblogPost',
    SIOCt+'BlogPost',
    SIOCt+'BoardPost',
    SIOCt+'WikiArticle',
    SIOCt+'WikiArticleSection',
  ]
  
  Contain = {
    SIOCt+'BoardPost' => SIOC+'Forum',
  }

  ViewGroup['#typeSelector'] = -> graph, e {
    Creatable.map{|c|
      {_: :a, style: 'font-size: 2em; display:block', c: c.R.fragment, href: e['REQUEST_PATH']+'?new&type='+c.shorten}}}

  ViewGroup['#editor'] = -> graph, e { # <form> for basic resource-edits

    fragment = e.q['fragment'].do{|s|s.slugify} || '' # fragment-id
    subject = s = e.uri + '#' + fragment              # URI
    model = graph[subject] || {'uri' => subject}      # resource state
    e.q['type'].do{|t|
      model[Type] ||= t.expand.R}
    model[Title] ||= ''
    model[Content] ||= ''
    contain = false

    [H.css('/css/html'), H.css('/css/wiki'), # View
     {_: :form, name: :editor, method: :POST, action: e['REQUEST_PATH'],
       c: [{_: :table, class: :html,
             c: [{_: :tr, c: {_: :td, colspan: 2,
                     c: [{_: :a, class: :uri, c: s, href: s},
                         {_: :a, class: :history, c: 'history', href: R[s].fragmentPath + '?set=page'}
                        ]}},
                 model.keys.-(['uri']).map{|p|
                   {_: :tr,
                     c: [{_: :td, class: :key, c: {_: :a, href: p, c: p.R.abbr}},
                         {_: :td, c: model[p].do{|o|
                             o.justArray.map{|o|
                               case p
                               when Type
                                 contain = true if Contain[o.uri]
                                 [{_: :input, type: :hidden,  name: Type, value: o.uri}, o.R.href]
                               when Content
                                 {_: :textarea, name: p, c: o, rows: 16, cols: 80}
                               when Date
                                 {_: :input, name: p, type: :datetime, value: !o || o.empty? && Time.now.iso8601 || o}
                               else
                                 {_: :input, name: p, value: o.respond_to?(:uri) ? o.uri : o, size: 54}
                               end }}}].cr}}].cr},
          ({_: :input, type: :hidden, name: :contain, value: true} if contain),
           {_: :input, type: :hidden, name: :fragment, value: fragment},
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
