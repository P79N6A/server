#watch __FILE__
class R

  View['vowl'] = -> d,e {
    prefix = '//js.whats-your.name/'
    [H.js(prefix + 'd3'),
     H.js(prefix + 'vowl/VOWL'),
     H.js(prefix + 'vowl/aVOWL'),
     {id: :graph, data: e['REQUEST_PATH']+'.json?format=vowl'},'VOWL',
    ]}

  View['d3'] = -> d,e {


  }

  JSONview['d3'] = -> d,e {
    
  }

  JSONview['vowl'] = -> d,e {
    n = []
    l = []
    d.triples{|s,p,o|
      
    }
    { 'info' => [{ 'title' => 'vowl',
                   'url' => e['REQUEST_PATH']}],
      'nodes' => n,
      'links' => l,
    }}

end
