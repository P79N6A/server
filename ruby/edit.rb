watch __FILE__
class E

  Prototypes = {
    SIOCt+'MicroblogPost' => [Content],
    SIOCt+'BlogPost' => [Date, Title, Content], nil=>nil,
    'blank'=>[]
  }

  F['protograph/create'] = F['protograph/_']
  F['protograph/edit'] = F['protograph/_']

  fn 'graph/create',->e,env,g{env['view']||='create'}
  fn 'graph/edit',->e,env,g{
    env['view']||='edit'
    e.fromStream g, :triplrFsStore }

  fn 'view/create',->g,e{
    [{_: :style, c: 'a {display:block;font-size:2em}'},{_: :b, c: :create},
     Prototypes.map{|s,_| s.nil? ? {_: :b, c: '&nbsp;'} : {_: :a, href:  e['REQUEST_PATH']+'?graph=edit&prototype='+(CGI.escape s), c: s.label}}]}

  fn 'view/edit',->g,e{
    triple = ->s,p,o{
      if s && p && o
        s = s.E
        p = p.E
        oE = p.literal o
        (id = s.concatURI(p).concatURI oE
        [(case p
          when Content
            {_: :textarea, name: id, c: o, rows: 24, cols: 80}
          when Date
            {_: :input, name: id, type: :datetime, value: o.empty? ? Time.now.iso8601 : o}
          else
            {_: :input, name: id, value: o, size: 54}
          end
          ),"<br>\n"]) if oE
      end}
    
    ps = []
    e.q['prototype'].do{|pr| Prototypes[pr].do{|v|
        g[e['uri']+'#'] ||= {}
        ps.concat v }}
    e.q['p'].do{|p| ps.push p }

    [(H.once e, 'edit', (H.css '/css/edit')),
     {_: :form, name: :editor, method: :POST, action: e['REQUEST_PATH'],

       # each resource
       c: [ g.map{|s,r|
              url = s.E.localURL e 
              # per-resource links
              {class: :resource, c:
              [{_: :a, class: :uri, id: s, c: s, href: url},
               {_: :a, class: :edit, c: '+predicate', href: url+'?graph=_&view=addP'},'<br><br>',

               # each property
#               r.keys.concat(ps).uniq.-(['uri']).map{|p|
               (r.keys.concat(ps).uniq.map{|p|
                 [{_: :b, c: p}, '<br>',
                  r[p].do{|o| [*o].map{|o|triple[s,p,o]}}, # existing triples
                  triple[e['uri'],p,''], '<br>']} if r.class==Hash)]} if s.match(/#/)}, # create triple
       {_: :input, type: :submit, value: 'save'}]}]}

  # select a property to edit
  fn 'view/addP',->g,e{
    [(H.once e, 'edit', (H.css '/css/edit')),
     [Date,Title,Creator,Content,Label].map{|p|{_: :a, href: p, c: p.label+' '}},

     {_: :form, action: e['REQUEST_PATH'], method: :GET,
       c: [{_: :input, type: :url, name: :p, pattern: '^http.*$', size: 64},
           {_: :input, type: :submit, value: 'property'}]}]}

end
