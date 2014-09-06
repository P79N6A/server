#watch __FILE__
class R

  View['edit'] = -> graph, e { # edit a RDF resource using a HTML <form>

    fragment = e.q['fragment'].do{|s|s.slugify} || '' # repeat fragment in QS for section selection
    subject = s = e.uri + '#' + fragment
    model = graph[subject] || {'uri' => subject}

    # on-resource, parametric, or default RDF-type for predicate-suggest
    type = model[Type].do{|t|t[0].uri} || e.q['type'] || SIOCt+'WikiArticleSection'
    Predicates[type].do{|ps| ps.map{|p| model[p] ||= "" }} # suggest predicates

    [H.css('/css/html'),
     {_: :form, name: :editor, method: :POST, action: e['REQUEST_PATH'],
       c: [{_: :table, class: :html,
             c: [{_: :tr, c: {_: :td, colspan: 2, c: {_: :a, class: :uri, c: (model[Title] || s), href: s}}},
                 model.keys.-(['uri',Type]).map{|p|
                   {_: :tr,
                     c: [{_: :td, class: :key, c: {_: :a, title: p, href: p, c: p.R.abbr}},
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

  View[SIOCt+'WikiArticleSection'] = -> g,e {
    g.map{|u,r| i = u.R
      {class: :wiki, style: 'border: .1em solid #eee; border-radius: .5em; padding: .5em',
        c: [{_: :a, href: u, c: {_: :h1, c: r[Title]}},
            {_: :a, href: i.docroot +  '?view=edit&fragment=' + i.fragment, c: '[edit]', style: 'float: right'},
            r[Content]]}}}

  Predicates = {
    SIOCt+'MicroblogPost' => [Content],
    SIOCt+'BlogPost' => [Title, Content],
    SIOCt+'WikiArticleSection' => [Title, Content]}

end
