#watch __FILE__
class R

  Prototypes = {
    SIOCt+'MicroblogPost' => [Content],
    SIOCt+'BlogPost' => [Title, Content],
    SIOCt+'WikiArticle' => [Title, Content],
  }

  # 404 -> create resource
  F['protograph/create'] = -> e,env,g {
    env['view'] = 'create'
    F['protograph/blank'][e,env,g]}

  # prototype select
  fn 'view/create',->g,e{
    [{_: :style, c: 'a {display:block;font-size:2em}'},{_: :b, c: :type},
     Prototypes.map{|t,ps|
       {_: :a, href:  e['REQUEST_PATH']+'?graph=edit&prototype='+(URI.escape t.shorten), c: t.label}}]}

  # editable triples
  F['protograph/edit'] = -> e,env,g {
    env['view'] ||= 'edit'          # use edit-view
    g[e.uri+'#'] = {}               # add current resource
    rand.to_s.h}
    
  fn 'graph/edit',->e,env,g{
    puts "graph.edit #{e}"
    e.fromStream g, :triplrDoc} # add fs-sourced triples
    
=begin HTML <form> RDF editor
      arg
      prototype - initialize fields for a resource-type
      predicate - initialize field for a particular predicate
=end
  fn 'view/edit',->g,e{

    # render a triple
    triple = ->s,p,o{ # http://dev.w3.org/html5/markup/input.html#input
      spo = o && s.R.predicatePath(p).objectPath(o)[0].uri
      t = CGI.escape [s,p,spo].to_json
      [(case p.R.uri
        when Content
          [{_: :textarea, name: t, c: o, rows: 16, cols: 80},
           '<br>',o]
        when Date
          {_: :input, name: t, type: :datetime, value: !o || o.empty? && Time.now.iso8601 || o}
        else
          {_: :input, name: t, value: o, size: 54}
        end
        ),"<br>\n"]}
    
    ps = [] # predicates to go editable on
    e.q['prototype'].do{|pr| pr = pr.expand
      Prototypes[pr].do{|v|ps.concat v }} # prototype imports
    e.q['predicate'].do{|p|ps.push p }    # explicit predicate

    [H.css('/css/html'),
     {_: :form, name: :editor, method: :POST, action: e['REQUEST_PATH'],

       c: [{_: :a, class: :edit, c: '+add field',
             href: e['uri']+'?graph=blank&view=addP', style: 'background-color:#0f0;border-radius:5em;color:#000;padding:.5em'},
           g.map{|s,r| # subject
             uri = s.R.localURL e
             {_: :table, class: :html,
               c: [{_: :tr, c: {_: :td, colspan: 2, c: {_: :a, class: :uri, id: s, c: s, href: uri}}},
                   r.keys.-([Edit]).concat(ps).uniq.map{|p| # resource + prototype/initialize predicates
                     {_: :tr,
                       c: [{_: :td, class: :key, c: {_: :a, title: p, href: p, c: p.abbrURI}}, # property
                           {_: :td,
                             c: [r[p].do{|o|                            # objects
                                   (o.class == Array ? o : [o]).map{|o| # each object
                                     triple[s,p,o]}},                   # existing triples
                                 triple[s,p,nil]]}]}}]}},                # new triple
           {_: :input, type: :submit, value: 'save'}]}]}

  # select a property to edit
  fn 'view/addP',->g,e{
    [[Date,Title,Creator,Content,Label].map{|p|[{_: :a, href: p, c: p},'<br>']},
     {_: :form, action: e['REQUEST_PATH'], method: :GET,
       c: [{_: :input, type: :url, name: :predicate, pattern: '^http.*$', size: 64},
           {_: :input, type: :hidden, name: :graph, value: :edit},
           {_: :input, type: :submit, value: 'property'}]}]}

end
