#watch __FILE__
class E

  F["?"]||={}
  F["?"].update({'taft'=>{
                'graph'=>'|',
                    '|'=>'triplrMozHist',
                 'view'=>'page',
                    'v'=>'timegraph',
                  'arc'=>'referer'}})

  # massage data for timegraph
  fn 'filter/timegraph',->e,m,_{

    x = e['x'] || Date # x prop
    y = e['y']         # y property

    # 2D values
    vX = m.map{|_,r|r[x]}.flatten.compact.map(&:to_time).map &:to_f
    vY = m.map{|_,r|r[y]}.flatten.compact.map &:to_f
    maxX = vX.max
    minX = vX.min
    maxY = vY.max
    minY = vY.min

    # scaling-ratio to normalize values to %
    scaleX = 100/((maxX-minX).do{|v|v==0 ? 100 : v}||100)
    scaleY = 100/((maxY-minY).do{|v|v==0 ? 100 : v}||100)

    # annotate resources with positioning data
    m.map{|u,r|
      r['x'] = [*r[x]][0].do{|v|(maxX - v.to_time.to_f)*scaleX} || 0
      r['y'] = y.do{|y|[*r[y]][0].do{|v|(maxY - v.to_f)*scaleY} || 0} || rand(100)}
  }

  # a linked-timeline view
  fn 'view/timegraph',->d,e{
    # use standard structure for examine faceted-filtering
   i=F['view/timegraph/item']
    Fn 'view/timegraph/base',d,e,->{d.map{|u,r|i.(r,e)}}}
  
  # timegraph container-element
  fn 'view/timegraph/base',->d,e,c{
    e[:graph] = d
    [H.css('/css/timegraph'),{class: :timegraph, c: c.()}, '<div style="float: right">']}

  # timegraph entry
  fn 'view/timegraph/item',->r,x{
    # skip resources w/o x-axis field
    if r[x.q['x'] || Date]

      [{style: "top: #{r['x']}%; left: 0", class: :date, c: r[Date][0]},
       {style: "top: #{r['x']}%; left: #{r['y']}%",
         c: [{_: :a, href: r.url, c: '#', class: :link},
             {_: :a, title: r[Date], href: '#'+r.uri, c: r[x.q['label'].expand], class: :label }]},
       
       # arc(s)
       {_: :svg, c:
         r[x.q['arc'].expand].map{|e|
           # target resource
           x[:graph][e.uri].do{|e|
             # arc path
             {_: :line, class: :arc, stroke: '#0ff',
               y1: e['x'].to_s+'%', x1: e['y'].to_s+'%',
               y2: r['x'].to_s+'%', x2: r['y'].to_s+'%'}}}}]
    end }
  
end
