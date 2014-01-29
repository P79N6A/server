watch __FILE__
class E

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
       {_: :a, href:  e['REQUEST_PATH']+'?graph=edit&prototype='+(CGI.escape t), c: t.label}}]}

  # editable triples
  F['protograph/edit'] = -> e,env,g {
    env['view'] ||= 'edit'          # use edit-view
    g[e.uri+'#'] = {}               # add current resource
    rand.to_s.h}
    
  fn 'graph/edit',->e,env,g{
    e.fromStream g, :triplrDoc} # add fs-sourced triples
    
=begin HTML <form> RDF editor
      arg
      prototype - initialize fields for a resource-type
      predicate - initialize field for a particular predicate
=end
  fn 'view/edit',->g,e{

    # render a triple
    triple = ->s,p,o{
      if s && p && o
        s = s.E
        p = p.E
        oE = p.literal o                 # cast literal to URI
        id = s.concatURI(p).concatURI oE # triple identifier
        [(case p.uri                     # more to support here.. http://dev.w3.org/html5/markup/input.html#input
          when Content
            [{_: :textarea, name: id, c: o, rows: 16, cols: 80},
            '<br>',o]
          when Date
            {_: :input, name: id, type: :datetime, value: o.empty? ? Time.now.iso8601 : o}
          else
            {_: :input, name: id, value: o, size: 54}
          end
          ),"<br>\n"]
      end}
   
    ps = [] # predicates to go editable on
    e.q['prototype'].do{|pr|
      Prototypes[pr].do{|v|ps.concat v }} # prototype imports
    e.q['predicate'].do{|p|ps.push p }    # explicit predicate

    [{_: :style, c: ".abbr {display: none}\ntd {vertical-align:top}"},
     {_: :form, name: :editor, method: :POST, action: e['REQUEST_PATH'],

       c: [{_: :a, class: :edit, c: '+add field',
             href: e['uri']+'?graph=blank&view=addP', style: 'background-color:#0f0;border-radius:5em;color:#000;padding:.5em'},
           g.map{|s,r| # subject
             uri = s.E.localURL e
             {_: :table, style: 'background-color:#eee',
               c: [{_: :tr, c: {_: :td, colspan: 2, c: {_: :a, class: :uri, id: s, c: s, href: uri}}},
                   {_: :input, type: :hidden, name: s.E.concatURI(Edit.E).concatURI(E['/']), value: e['uri']+'?graph=edit'},
                   r.keys.-([Edit]).concat(ps).uniq.map{|p| # resource + prototype/initialize predicates
                     {_: :tr,
                       c: [{_: :td, c: {_: :a, title: p, href: p, c: p.abbrURI}}, # property
                           {_: :td,
                             c: [r[p].do{|o|                            # objects
                                   (o.class == Array ? o : [o]).map{|o| # each object
                                     triple[s,p,o]}},                   # existing triples
                                 triple[s,p,'']]}]}}]}},                # new triple
           {_: :input, type: :submit, value: 'save'}]}]}

  # select a property to edit
  fn 'view/addP',->g,e{
    [[Date,Title,Creator,Content,Label].map{|p|[{_: :a, href: p, c: p},'<br>']},
     {_: :form, action: e['REQUEST_PATH'], method: :GET,
       c: [{_: :input, type: :url, name: :predicate, pattern: '^http.*$', size: 64},
           {_: :input, type: :hidden, name: :graph, value: :edit},
           {_: :input, type: :submit, value: 'property'}]}]}

end
