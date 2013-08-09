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

    # group resources on shared predicate/object tuples
    m.values.group_by{|r|
      [*r[e['group']]][0]}.

    map{|g,v| # within each group

      p = nil # previous in time-series

      # sort by specified x-axis or Date
      v.sort_by{|r|
        [*r[e['x'] || Date]][0].to_time}.

      # link time-series entries 
      map{|r|
        r['/prev'] = [p]
        p = r } 
    }}

  # a linked-timeline view
  fn 'view/timegraph',->d,e{
    # use standard structure for examine faceted-filtering
   i=F['view/timegraph/item']
    Fn 'view/timegraph/base',d,e,->{d.map{|u,r|i.(r,e)}}}
  
  fn 'view/timegraph/base',->d,e,c{
    e[:graph] ||= d      # graph
    g = {}               # groups
    a = e.q['x'] || Date # x-axis

    # values
    v = d.map{|_,r|r[a]}.flatten.compact.map(&:to_time).map &:to_f
    o = d.map{|_,r|r[e.q['y']]}.flatten.compact.map &:to_f
    max = v.max
    min = v.min
    omax = o.max
    omin = o.min

    # scaling-ratio to normalize values
    scale = 100/((max - min).do{|v|v==0 ? 100 : v}||100)
   oscale = 100/((omax-omin).do{|v|v==0 ? 100 : v}||100)

    # add CSS to model
    d.map{|_,r| r[a] &&
      # group-identifier
      (t = e.q['group'].do{|g|
         [*r[g.expand]][0]} ||                      # custom predicate
       [*r[Title]][0].sub(/^[rR][eE][^A-Za-z]./,'') # default

       # x position
       r['left']=[*r[a]][0].do{|v|(v.to_time.to_f-min)*scale}||0

       # y position
       r['top']=e.q['y'].do{|a|[*r[a]][0].do{|v|(omax - v.to_f)*oscale}||0}|| rand(100)

       # group
       r['group'] = (g[t] ||= # memoize for other members
                 {c: '#%06x' % rand(16777216), a: r.url,
                   t: r['top'], l: r['left']}))}

    # output

    [H.css('/css/time'),
     {class: :tg, c: [{_: :svg, c: c.()},

      # group labels
       g.map{|t,g|
         {c: {_: :a, c: t, href: g[:a]}, class: :gtitle,
           style: "background-color: #{g[:c]}; top:#{g[:t]/4.0}em; left:#{g[:l]}%"}}]}]}

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
