#watch __FILE__
class E

  F["?"]||={}
  F["?"].update({'arc'=>{
                    'view' => 'protovis',
                    'protovis.data' => 'protovis/net',
                    'protovis.view' => 'arc'
                  }})

  fn 'protovis/net',->d,e{
    i=-1
    x={} # uri -> index
    a=[] # arcs
    d.values.each{|r|
      r.triples{|s,p,o|
        o.respond_to?(:uri) &&
        o.uri.do{|o|
          x[s]||=i+=1
          x[o]||=i+=1
          a.push({source: x[s], target: x[o], value: 3})}}}
    {nodes: x.map{|u,_|{nodeName: d[u][Title]||u.label, group: 0}},
      links: a}}
  
  fn 'view/protovis',->d,e{
    [H.js('/js/protovis/protovis-r3.2'),{id: :fig},
     {_: :script,type: 'text/javascript+protovis',
       c: ['var d='+(Fn e.q['protovis.data'],d,e).to_json,
           E['http://'+e['SERVER_NAME']+'/js/protovis/'+e.q['protovis.view']+'.js'].r].cr}]}
end
