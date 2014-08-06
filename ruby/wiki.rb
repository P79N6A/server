#watch __FILE__
class R

  Prototypes = { # suggest properties for resource
    SIOCt+'MicroblogPost' => [Content],
    SIOCt+'BlogPost' => [Title, Content],
    SIOCt+'WikiArticlePart' => [Title, Content]}


  View['edit'] = -> g,e {
    if e.q.has_key? 'predicate'
      View['editPredicate'][g,e]
    else
      View['editResource'][g,e]
    end}

  View['editResource'] = -> g,e {
    triple = ->s,p,o{ # triple -> <input>
      obj = o && s.R.predicatePath(p).objectPath(o)[0].uri # object URI
      t = CGI.escape [s,p,obj].to_json # s,p,o -> key
      [(case p.R.uri
        when Content
          [{_: :textarea, name: t, c: o, rows: 16, cols: 80}, # <textarea>
           '<br>',o]
        when Date
          {_: :input, name: t, type: :datetime, value: !o || o.empty? && Time.now.iso8601 || o} # <input type=datetime>
        else
          {_: :input, name: t, value: o.respond_to?(:uri) ? o.uri : o, size: 54} # <input> - URIs and plaintext 
        end),"<br>\n"]}

    ps = [] # predicates
    e.q['type'].do{|p| Prototypes[p.expand].do{|v| ps.concat v }} # predicates via explicit type-class
    e.q['p'].do{|p|ps.push p } # explicit predicate
    mono = e.q.has_key? 'mono' # max(1) val-per-key

    [H.css('/css/html'), {_: :form, name: :editor, method: :POST, action: e['REQUEST_PATH'], # <form>
       c: [{_: :a, class: :edit, c: 'add predicate', href: e['REQUEST_PATH']+'?view=edit&predicate'}, # link to add predicate
          g.values.select{|r|r.uri.match /#/}.map{|r|
             s = r.uri # subject URI
             predicates = r.keys.except('uri').concat ps # predicates via resource-state
             r[Type].justArray.compact.map{|p| Prototypes[p.uri].do{|v| predicates.concat v}} # predicates via type-class

             {_: :table, class: :html, # resource
               c: [{_: :tr, c: {_: :td, colspan: 2, c: {_: :a, class: :uri, id: s, c: s, href: s}}}, # subject
                   predicates.uniq.map{|p| # each predicate
                     {_: :tr,
                       c: [{_: :td, class: :key, c: {_: :a, title: p, href: p, c: p.R.abbr}}, # predicate
                           {_: :td, c: [r[p].do{|o|       # object(s)
                                   o.justArray.map{|o|    # each object
                                     triple[s,p,o]}},     # editable triple
                                 (triple[s,p,nil] unless mono && r[p]) # create a triple
                                ]}]}}]} unless s=='#'},
          ({_: :input, type: :hidden, name: :mono, value: :true} if mono),
           {_: :input, type: :submit, value: 'save'}]}]}

  View['editPredicate'] = -> g,e {
    [[Date,Title,Creator,Content,Label].map{|p| # common predicates
       [{_: :a, href: e['REQUEST_PATH']+{'p' => p, 'view' => 'edit'}.qs, c: p},
        '<br>']},
     {_: :form, action: e['REQUEST_PATH'], method: :GET,
       c: [{_: :input, type: :url, name: :p, pattern: '^http.*$', size: 64},
           {_: :input, type: :hidden, name: :view, value: :edit},
           {_: :input, type: :submit, value: 'property'}]}]}

  View[SIOCt+'WikiArticlePart'] = -> g,e {
    g.map{|u,r|
      {class: :wiki, style: 'border: .1em solid #eee; border-radius: .5em; padding: .5em',
        c: [{_: :a, href: u, c: {_: :h1, c: r[Title]}},
            {_: :a, href: u.R.docroot + '?view=edit&mono', c: '[edit]', style: 'float: right'},
            r[Content]]}}}

end
