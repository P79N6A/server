watch __FILE__
class E

  Prototypes = {
    SIOCt+'MicroblogPost' => [Content],
    SIOCt+'BlogPost' => [Title, Content],    
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
  F['protograph/edit'] = F['protograph/blank']
  fn 'graph/edit',->e,env,g{
    env['view'] ||= 'edit'          # use edit-view
    g[e.uri] = {}                   # add current resource
    e.fromStream g, :triplrFsStore} # add fs-sourced triples
    
=begin HTML <form> based RDF-editor
      optional arguments: 
      prototype - initialize fields for a resource-type
      predicate - initialize field for a particular predicate
=end
  fn 'view/edit',->g,e{

    # render a triple
    triple = ->s,p,o{ puts "triple #{s} #{p} #{o}"
      if s && p && o
        s = s.E
        p = p.E
        oE = p.literal o                  # cast literal to URI
        (id = s.concatURI(p).concatURI oE # triple identifier
        [(case p                          # more to support here.. http://dev.w3.org/html5/markup/input.html#input
          when Content
            {_: :textarea, name: id, c: o, rows: 24, cols: 80}
          when Date
            {_: :input, name: id, type: :datetime, value: o.empty? ? Time.now.iso8601 : o}
          else
            {_: :input, name: id, value: o, size: 54}
          end
          ),"<br>\n"]) if oE
      end}
   
    ps = [] # predicates to show as editable
    e.q['prototype'].do{|pr|
      Prototypes[pr].do{|v|ps.concat v }} # prototype attributes
    e.q['predicate'].do{|p|ps.push p }    # explicit

    [(H.once e, 'edit', (H.css '/css/edit')),
     {_: :form, name: :editor, method: :POST, action: e['REQUEST_PATH'],

       # each resource
       c: [g.map{|s,r|
             uri = s.E.localURL e
              {class: :resource, c:
              [{_: :a, class: :uri, id: s, c: s, href: uri},
               {_: :a, class: :edit, c: '+property', href: uri+'?graph=blank&view=addP'},'<br><br>',

               (r.keys.concat(ps).uniq.map{|p| # resource + prototype/initialize predicates
                 [{_: :b, c: p}, '<br>',       # property label
                  r[p].do{|o|                            # objects
                    (o.class == Array ? o : [o]).map{|o| # each object
                      triple[s,p,o]}},                   # show (existing) triples

                  triple[e['uri'],p,''], # field of new triple
                  
                  '<br>']} if r.class==Hash)]}},
           {_: :input, type: :submit, value: 'save'}]}]}

  # select a property to edit
  fn 'view/addP',->g,e{
    [(H.once e, 'edit', (H.css '/css/edit')),
     [Date,Title,Creator,Content,Label].map{|p|{_: :a, href: p, c: p.label+' '}},

     {_: :form, action: e['REQUEST_PATH'], method: :GET,
       c: [{_: :input, type: :url, name: :p, pattern: '^http.*$', size: 64},
           {_: :input, type: :submit, value: 'property'}]}]}

end
