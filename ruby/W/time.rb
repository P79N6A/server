#watch __FILE__

class DateTime
  def html; H({_: :time, datetime: iso8601, c: to_s}) end
end

class Time
  def html; H({_: :time, datetime: iso8601, c: to_s}) end
end

class Object
  def time?
    (self.class == Time) || (self.class == DateTime)
  end
  def to_time
    time? ? self : Time.parse(self)
  rescue
    nil
  end
end

class E

  # linked-timeline
  fn 'view/timegraph',->g,e{
    i = F['view/timegraph/item']
    Fn 'view/timegraph/base',g,e,->{
      g.map{|u,r|i.(r,e)}}}
  
  # timegraph container-element
  fn 'view/timegraph/base',->d,e,c{
    Fn 'filter/timegraph', e.q,d,nil

    e[:graph] = d
    e[:group] = {}
    e[:color] = E.c

    [H.css('/css/timegraph'),{class: :timegraph, c: c.()}]}

  # timegraph entry
  fn 'view/timegraph/item',->r,x{

    # on resources w x-axis field
    if r[x.q['x'] || Date]

      labelP = x.q['label'].expand || Creator
      label = (r[labelP][0]).do{|l|
               l.respond_to?(:uri) ? l.uri : l.to_s}
      lc = x[:group][label] ||= E.c

      [{style: "top: #{r['x']}%; left: 0", class: :date, c: r[Date][0]},
       {style: "top: #{r['x']}%; left: #{r['y']}%",
         c: [{_: :a, href: r.url, c: '#', class: :link},
             {_: :a,
               title: r[Date][0],
               href: '#'+r.uri,
               class: :label,
               style: "background-color: #{lc}",
               c: label,
             }]},
       
       # arc(s)
       {_: :svg, c:
         r[x.q['arc'].expand].map{|e|
           # target resource
           x[:graph][e.uri].do{|e|
             # arc path
             {_: :line, class: :arc, stroke: x[:color], 'stroke-dasharray'=>"2,2",
               y1: e['x'].to_s+'%', x1: e['y'].to_s+'%',
               y2: r['x'].to_s+'%', x2: r['y'].to_s+'%'}}}}]
    end }

  fn 'filter/timegraph',->e,m,_{

    x = e['x'] || Date # x property
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

    # annotate resources
    m.map{|u,r|
      r['x'] = [*r[x]][0].do{|v|(maxX - v.to_time.to_f)*scaleX} || 0
      r['y'] = y.do{|y|[*r[y]][0].do{|v|(maxY - v.to_f)*scaleY} || 0} || rand(100)}}

 ## SIMILE Timeline 
 #  http://www.simile-widgets.org/

  # JSON format
  fn Render+'application/timeline',->d,e{
    {dateTimeFormat: 'iso8601',
      events: d.values.map{|r|
        r[Date].do{|d|
          {description: r.uri,
          title: r[Title],
          start: [*d][0],
          link: r.url,
        }}}.compact}.to_json}

  fn 'head/timeline',->d,e{
  ['<script>var t="'+e['REQUEST_PATH']+e.q.except('view','?').merge({format: 'application/timeline'}).qs+'"</script>',
   (H.js '/js/timeline'),
   (H.js 'http://api.simile-widgets.org/timeline/2.3.1/timeline-api')]}

  fn 'view/timeline',->d,e{'<div id="tl" class="timeline-default" style="height: 300px;"></div>'}

end
