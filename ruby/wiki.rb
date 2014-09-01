watch __FILE__
class R

  View['edit'] = -> graph, e {

    type = e.q['type'] || SIOCt+'WikiArticle'
    section = e.q['section'] || ''
    s = e.uri + '#' + section # subject URI
    model = graph[s] || {'uri' => s, Type => type}
    Prototypes[type].do{|proto|
      proto.map{|p|
        model[p] ||= "" # blank field
      }}
    
    [H.css('/css/html'),
     {_: :form, name: :editor, method: :POST, action: e['REQUEST_PATH'],
       c: [{_: :table, class: :html,
             c: [{_: :tr, c: {_: :td, colspan: 2, c: {_: :a, class: :uri, c: (model[Title] || s), href: s}}},
                 model.keys.-(['uri',Type]).map{|p|
                   puts "p"
                   {_: :tr,
                     c: [{_: :td, class: :key, c: {_: :a, title: p, href: p, c: p.R.abbr}}, # predicate
                         {_: :td, c: model[p].do{|o|
                             o.justArray.map{|o|
                               case p
                               when Content
                                 {_: :textarea, name: p, c: o, rows: 16, cols: 80}
                               when Date
                                 {_: :input, name: p, type: :datetime, value: !o || o.empty? && Time.now.iso8601 || o}
                               else
                                 {_: :input, name: p, value: o.respond_to?(:uri) ? o.uri : o, size: 54}
                               end }}}]}}]},
           {_: :input, type: :hidden, name: Type, value: type},
           {_: :input, type: :hidden, name: :section, value: section},
           {_: :input, type: :submit, value: 'write'}]}]}

  View[SIOCt+'WikiArticle'] = -> g,e {
    g.map{|u,r|
      {class: :wiki, style: 'border: .1em solid #eee; border-radius: .5em; padding: .5em',
        c: [{_: :a, href: u, c: {_: :h1, c: r[Title]}},
            {_: :a, href: u.R.docroot + '?view=edit', c: '[edit]', style: 'float: right'},
            r[Content]]}}}

  Prototypes = {
    SIOCt+'MicroblogPost' => [Content],
    SIOCt+'BlogPost' => [Title, Content],
    SIOCt+'WikiArticle' => [Title, Content]}

end
