#watch __FILE__
class E

  F["?"]||={}
  F["?"].update({'taft'=>{
                'graph'=>'|',
                    '|'=>'triplrMozHist',
                 'view'=>'page',
                    'v'=>'timegraph',
                  'arc'=>'referer',
                'label'=>'uri'}})

  # massage data for timegraph
  fn 'filter/timegraph',->e,m,_{

    x = e['x'] || Date # x prop
    y = e['y']         # y property
    g = {}             # groups

    # 2D values
    vX = m.map{|_,r|r[x]}.flatten.compact.map(&:to_time).map &:to_f
    vY = m.map{|_,r|r[y]}.flatten.compact.map &:to_f
    maxX = vX.max
    minX = vX.min
    maxY = vY.max
    minY = vY.min

    # scaling-ratio to normalize values
    scaleX = 100/((maxX-minX).do{|v|v==0 ? 100 : v}||100)
    scaleY = 100/((maxY-minY).do{|v|v==0 ? 100 : v}||100)

    # annotate resources with positioning data
    m.map{|u,r|
      r['left'] = [*r[x]][0].do{|v|(v.to_time.to_f-minX)*scaleX} || 0
      r['top'] = y.do{|y|[*r[y]][0].do{|v|(maxY - v.to_f)*scaleY} || 0} || rand(100)}
  }

  # a linked-timeline view
  fn 'view/timegraph',->d,e{
    # use standard structure for examine faceted-filtering
   i=F['view/timegraph/item']
    Fn 'view/timegraph/base',d,e,->{d.map{|u,r|i.(r,e)}}}
  
  # timegraph container-element
  fn 'view/timegraph/base',->d,e,c{
    [H.css('/css/timegraph'),
     {class: :tg, c: {_: :svg, c: c.()}}]}

  # timegraph entry
  fn 'view/timegraph/item',->r,x{ r[x.q['x']||Date] &&
    (t = r['top'].to_s+'%'
     l = r['left'].to_s+'%'
     [r[x.q['arc'].expand||'/prev'].map{|e|
        x[:graph][e.uri].do{|e|
          {_: :line, class: :arc, stroke: r['group'][:c], style: "stroke-width:.3em",
                       y1: e['top'].to_s+'%', x1: e['left'].to_s+'%',
                       y2: t, x2: l}}},
        {_: :circle, onclick: "document.location.href=\"#{r.url}\"", fill: r['group'][:c],r: '.42em', cy: t, cx: l},
        x.q['label'].do{|a|
          l = r['left'] > 96 ? '96%' : l
          {_: :text,fill: 'yellow', y: t, x: l,
            c: a.split(/,/).map{|a|
              {_: :tspan,x:l,dy: "1em",
                c: CGI.escapeHTML([*r[a.expand]][0].do{|l|(l.respond_to?(:uri) ? l.uri : l.to_s[0..64]).sub(/^http.../,'')})}}}}])}

end
