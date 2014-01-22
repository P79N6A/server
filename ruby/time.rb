watch __FILE__

class Time
  def html e=nil,g=nil; H({_: :time, datetime: iso8601, c: to_s}) end
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

  fn 'view/timegraph',->g,e{
    i = F['itemview/timegraph']
    Fn 'baseview/timegraph',g,e,->{
      g.map{|u,r|i.(r,e)}}}

  fn 'baseview/timegraph',->d,e,c{
    Fn 'filter/timegraph', e.q,d,nil

    e[:graph] = d
    e[:group] = {}
    e[:color] = E.cs
    h = e.q['height'].do{|h|h.match(/[0-9]+/) && h.to_i.min(1).max(1024) } || '64'
    

    [H.css('/css/timegraph'),{class: :timegraph, c: c.()},F['view'][d,e]]}

  # timegraph entry
  fn 'itemview/timegraph',->r,x{

    # on resources w x-axis field
    if r[x.q['x'] || Date]

      labelP = x.q['label'].do{|l|l.expand} || Creator
      label = ([*r[labelP]][0]).do{|l|
               l.respond_to?(:uri) ? l.E.label : l.to_s}
      lc = x[:group][label] ||= E.c
      arc = x.q['arc'].do{|a| a.expand } || (SIOC+'reply_of')

      [{style: "top: #{r['x']}%; left: #{r['y']}%",
         c: [{_: :a,
               title: r[Date][0],
               href: '#'+r.uri,
               class: :label,
               style: "border-color: #{lc};background-color: #{lc}",
               c: label.split('@')[0],
             }]},
       
       # arc(s)
       {_: :svg, c: r.class==Hash && r[arc].do{|a|a.map{|e|
             # target resource
             x[:graph][e.uri].do{|e|
               # arc path
               {_: :line, class: :arc, stroke: lc, 'stroke-dasharray' => '1,1', 
                 y1: e['x'].to_s+'%', x1: e['y'].to_s+'%',
                 y2: r['x'].to_s+'%', x2: r['y'].to_s+'%'}}}}}]
    end }

  F['view/timeofday']=->d,e{
    e.q['a']='timeofday'
    F['filter/timeofday'][e.q,d,nil]
    F['view/histogram'][d,e]}

  fn 'filter/timeofday',->e,m,_{
    m.map{|_,r|r[Date].do{|ds| ds.map{|d|
          d = d.to_time
          r['timeofday']=[60 * d.hour + d.min]}}}}

  fn 'filter/timegraph',->e,m,_{

    x = e['x'] || Date # x property
    y = e['y']         # y property

    # 2D values
    vX = m.map{|_,r|r[x] if r.class==Hash}.flatten.compact.map(&:to_time).map &:to_f
    vY = m.map{|_,r|r[y] if r.class==Hash}.flatten.compact.map &:to_f
    maxX = vX.max || 0
    minX = vX.min || 0
    maxY = vY.max || 0
    minY = vY.min || 0

    # scaling-ratio to normalize values to %
    scaleX = 100/((maxX-minX).do{|v|v==0 ? 100 : v}||100)
    scaleY = 100/((maxY-minY).do{|v|v==0 ? 100 : v}||100)

    # annotate resources
    m.map{|u,r|
      if r.class==Hash
        r['x'] = r[x].class==Array && r[x][0].do{|v|(maxX - v.to_time.to_f)*scaleX} || 0
        r['y'] = y.do{|y|[*r[y]][0].do{|v|(maxY - v.to_f)*scaleY} || 0} || rand(100)
      end
    }}

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
