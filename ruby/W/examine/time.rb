#watch __FILE__
class E

  fn 'filter/tg',->e,m,_{
    m.values.group_by{|r|[*r[e['group']]][0]}.map{|g,v|
      p=nil
      v.sort_by{|r|[*r[e['x']||Date]][0].to_time}.map{|r|
        r['/parent']=[p]
        p=r}}}

  fn 'view/tg',->d,e{
    i=F['view/tg/item']
    Fn 'view/tg/base',d,e,->{d.map{|u,r|i.(r,e)}}}
  
  fn 'view/tg/base',->d,e,c{ e[:graph]||=d
    g={} # groups
    a=e.q['x']||Date
    v=d.map{|_,r|r[a]}.flatten.compact.map(&:to_time).map &:to_f # time axis
    max = v.max
    min = v.min
    scale=100/((max - min).do{|v|v==0 ? 100 : v}||100) # scale time
    o=d.map{|_,r|r[e.q['y']]}.flatten.compact.map &:to_f # other axis
    omax = o.max; omin = o.min
    oscale=100/((omax - omin).do{|v|v==0 ? 100 : v}||100) # scale other
    d.map{|_,r| r[a] &&
      (t = e.q['group'].do{|g|[*r[g.expand]][0]}||[*r[Title]][0].sub(/^[rR][eE][^A-Za-z]./,'') # group id
       r['left']=[*r[a]][0].do{|v|(v.to_time.to_f-min)*scale}||0 # x position
       r['top']=e.q['y'].do{|a|[*r[a]][0].do{|v|(omax - v.to_f)*oscale}||0}|| rand(100) # y position
       r['group'] = (g[t] ||= # group config
                 {c: '#%06x' % rand(16777216), a: r.url,
                   t: r['top'], l: r['left']}))}

    [H.css('/css/time'),
     {class: :tg,
        c: [{_: :svg, c: c.()},
            g.map{|t,g|
              {c: {_: :a, c: t, href: g[:a]}, 
                class: :gtitle,
                  style: "background-color: #{g[:c]};top:#{g[:t]/4.0}em;left:#{g[:l]}%"}}]}]}

  fn 'view/tg/item',->r,x{ r[x.q['x']||Date] &&
    (t = r['top'].to_s+'%'
     l = r['left'].to_s+'%'
     [r[x.q['arc'].expand||'/parent'].map{|e|
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
