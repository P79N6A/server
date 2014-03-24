watch __FILE__
class R

  Prototypes = {
    SIOCt+'MicroblogPost' => [Content],
    SIOCt+'BlogPost' => [Title, Content],
    SIOCt+'WikiArticle' => [Title, Content],
  }

  fn 'view/edit',->g,e{

    # lambda to render a triple
    triple = ->s,p,o{
      spo = o && s.R.predicatePath(p).objectPath(o)[0].uri
      t = CGI.escape [s,p,spo].to_json
      [(case p.R.uri
        when Content
          [{_: :textarea, name: t, c: o, rows: 16, cols: 80},
           '<br>',o]
        when Date
          {_: :input, name: t, type: :datetime, value: !o || o.empty? && Time.now.iso8601 || o}
        else
          {_: :input, name: t, value: o.respond_to?(:uri) ? o.uri : o, size: 54}
        end
        ),"<br>\n"]}
    
    ps = [] # predicates to go editable on
    e.q['prototype'].do{|pr| pr = pr.expand
      Prototypes[pr].do{|v|ps.concat v }} # prototype imports
    e.q['predicate'].do{|p|ps.push p }    # explicit predicate
    mono = e.q.has_key? 'mono' # max 1 predicate->object field

    [H.css('/css/html'),
     {_: :form, name: :editor, method: :POST, action: e['REQUEST_PATH'],
       c: [{_: :a, class: :edit, c: 'add predicate', href: e['uri']+'?view=addP'},

           g.map{|s,r| # each (subject, resource)
             {_: :table, class: :html,
               c: [{_: :tr, c: {_: :td, colspan: 2, c: {_: :a, class: :uri, id: s, c: s, href: s}}}, # subject URI
                   r.keys.concat(ps).uniq.map{|p| # each editable predicate
                     {_: :tr,
                       c: [{_: :td, class: :key, c: {_: :a, title: p, href: p, c: p.abbrURI}}, # predicate URI
                           {_: :td, c: [r[p].do{|o|       # has object?
                                   o.justArray.map{|o|    # each object
                                     triple[s,p,o]}},     # render triples
                                 (triple[s,p,nil] unless r[p] && mono) # blank triple
                                ]}]}}]} unless s=='#'},
          ({_: :input, type: :hidden, name: :mono, value: :true} if mono),
           {_: :input, type: :submit, value: 'save'}]}]}

  # select a property to edit
  fn 'view/addP',->g,e{
    [[Date,Title,Creator,Content,Label].map{|p|[{_: :a, href: p, c: p},'<br>']},
     {_: :form, action: e['REQUEST_PATH'], method: :GET,
       c: [{_: :input, type: :url, name: :predicate, pattern: '^http.*$', size: 64},
           {_: :input, type: :hidden, name: :graph, value: :edit},
           {_: :input, type: :submit, value: 'property'}]}]}

end
