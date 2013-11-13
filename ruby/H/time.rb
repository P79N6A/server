#watch __FILE__

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
    e[:color] = E.cs
    h = e.q['height'].do{|h|h.match(/[0-9]+/) && h.to_i.min(1).max(1024) } || '64'
    

    [H.css('/css/timegraph'),{class: :timegraph, style: "height: #{h}em", c: c.()}]}

  # timegraph entry
  fn 'view/timegraph/item',->r,x{

    # on resources w x-axis field
    if r[x.q['x'] || Date]

      labelP = x.q['label'].do{|l|l.expand} || Creator
      label = ([*r[labelP]][0]).do{|l|
               l.respond_to?(:uri) ? l.uri : l.to_s}
      lc = x[:group][label] ||= E.c
      arc = x.q['arc'].do{|a| a.expand }

      [{style: "top: #{r['x']}%; left: #{r['y']}%",
         c: [{_: :a,
               title: r[Date][0],
               href: r.url,
               class: :label,
               style: "background-color: #{lc}",
               c: label,
             }]},
       
       # arc(s)
       {_: :svg, c:
         r[arc].do{|a|a.map{|e|
             # target resource
             x[:graph][e.uri].do{|e|
               # arc path
               {_: :line, class: :arc, stroke: x[:color], 'stroke-dasharray'=>"2,2",
                 y1: e['x'].to_s+'%', x1: e['y'].to_s+'%',
                 y2: r['x'].to_s+'%', x2: r['y'].to_s+'%'}}}}}]
    end }

  fn 'filter/timeofday',->e,m,_{
    m.map{|_,r|r[Date].do{|ds| ds.map{|d|
          d = d.to_time
          r['timeofday']=[60 * d.hour + d.min]}}}}

  fn 'filter/timegraph',->e,m,_{

    x = e['x'] || Date # x property
    y = e['y']         # y property

    # 2D values
    vX = m.map{|_,r|r[x]}.flatten.compact.map(&:to_time).map &:to_f
    vY = m.map{|_,r|r[y]}.flatten.compact.map &:to_f
    maxX = vX.max || 0
    minX = vX.min || 0
    maxY = vY.max || 0
    minY = vY.min || 0

    # scaling-ratio to normalize values to %
    scaleX = 100/((maxX-minX).do{|v|v==0 ? 100 : v}||100)
    scaleY = 100/((maxY-minY).do{|v|v==0 ? 100 : v}||100)

    # annotate resources
    m.map{|u,r|
      r['x'] = [*r[x]][0].do{|v|(maxX - v.to_time.to_f)*scaleX} || 0
      r['y'] = y.do{|y|[*r[y]][0].do{|v|(maxY - v.to_f)*scaleY} || 0} || rand(100)}}

 ## SIMILE Timeline 
 #  http://www.simile-widgets.org/

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

  # tripleStream -> tripleStream
  def dateNorm *f
    send(*f){|s,p,o|
      yield *({'CreationDate' => true,
               'Date' => true,
                RSS+'pubDate' => true,
                Date => true,
                Purl+'dc/elements/1.1/date' => true,
                Atom+'published' => true,
                Atom+'updated' => true
              }[p] ?
              [s,Date,Time.parse(o).utc.iso8601] : [s,p,o])}
  end

end
