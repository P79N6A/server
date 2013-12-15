watch __FILE__
class E

  F['protograph/editable'] = F['protograph/_']

  fn 'graph/editable',->e,env,g{
    e.fromStream g, :triplrFsStore}

  # select a prototype graph
  # , or go blank
  fn 'view/create',->g,e{
    [H.css('/css/create'),{_: :b, c: :create},
     Prototypes.map{|s,_|
       if s.nil?
         {_: :b, c: '&nbsp;'}
       else
         {_: :a, href:  e['REQUEST_PATH']+'?graph=_&view=edit&prototype='+(CGI.escape s), c: s.label}
       end}]}

  fn 'view/edit',->g,e{

    # input field for a triple
    # TODO more HTML5 typed-inputs
    triple = ->s,p,o{
      id = (s.E.concatURI p).concatURI E(p).literal o
      [(case p
        when Content
          {_: :textarea, name: id, c: o, rows: 24, cols: 80}
        else
          {_: :input, name: id, value: o}
        end
        ),"<br>\n"]}

    ps = []
    e.q['prototype'].do{|pr|
      Prototypes[pr].do{|v|
        ps = v}}

    # global assets
    [(H.once e, 'edit', (H.css '/css/edit')),
     {_: :form, name: :editor, method: :POST, action: e['REQUEST_PATH'],

       # each resource
       c: [ g.map{|s,r|
              url = s.E.localURL e 
              # per-resource links
              [{_: :a, class: :uri, id: s, c: s, href: url},
               {_: :a, class: :edit, c: '+predicate', href: url+'?graph=_&view=addP'},

               # each property
               r.keys.concat(ps).uniq.map{|p|[ {_: :b, c: p}, '<br>',
                  r[p].do{|os| os.map{|o|triple[s,p,o]}}, # existing triples
                  triple[e['uri'],p,'']]}]},              # create a triple

       {_: :input, type: :submit, value: 'save'}]}]}
  
  # select a property to edit
  fn 'view/addP',->g,e{
    [(H.once e, 'edit', (H.css '/css/edit')),

     # ubiquitous properties
     [Date,Title,Creator,Content,Label].map{|p|
       {_: :a, href: p, c: p.label+' '}},

     {_: :form, action: e['REQUEST_PATH'], method: :GET,
       c: [{_: :input, type: :url, name: :p, pattern: '^http.*$', size: 53},

           # editor args
           { filter: :p,
              graph: :editable,
               view: :editPO}.map{|n,v|
           {_: :input, type: :hidden, name: n, value: v}},

           {_: :input, type: :submit, value: 'property'}]}]}

end
