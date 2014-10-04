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

class R

  GET['/today'] = -> e,r {[303, {
                             'Location'=> Time.now.strftime('/%Y/%m/%d/?') + (r['QUERY_STRING']||''),
                             'Access-Control-Allow-Origin' => r['HTTP_ORIGIN'].do{|o|o.match(HTTP_URI) && o } || '*'
                           }, []]}

  View['timegraph'] = -> g,e {
    i = View['timegraph/item']
    View['timegraph/base'][g,e,->{g.map{|u,r|i.(r,e)}}]}

  View['timegraph/base'] = -> d,e,c {
    e[:graph] = d
    e[:group] = {}
    [H.css('/css/timegraph', true),
     DefaultView[Hash[d.sort_by{|u,r| r.class==Hash && r[Date].do{|d|d.justArray[0].to_s} || ''}.reverse],e],
     {class: :timegraph,
       c: (View['timegraph/filter'][ e.q, d, nil]
           c.())}]}

  View['timegraph/item'] = -> r,x {

    # on resources w x-axis field
    if r[x.q['x'] || Date]
      label = r[x.q['label'].do{|l|l.expand}||Creator].justArray[0].do{|l| l.R.fragment } || '#'
      lc = x[:group][label] ||= R.c
      arc = x.q['arc'].do{|a| a.expand } || (SIOC+'has_parent')

      [{style: "top: #{r['x']}%; left: #{r['y']}%",
         c: [{_: :a, title: r[Date][0], href: '#'+r.uri, class: :label,
               style: "border-color: #{lc};background-color: #{lc}", c: label}]},
       
       # arc(s)
       {_: :svg, c: r.class==Hash && r[arc].do{|a|a.map{|e|
             # target resource
             x[:graph][e.uri].do{|e|
               # arc path
               {_: :line, class: :arc, stroke: lc, 'stroke-dasharray' => '1,1', 
                 y1: e['x'].to_s+'%', x1: e['y'].to_s+'%',
                 y2: r['x'].to_s+'%', x2: r['y'].to_s+'%'}}}}}]
    end }

  View['timegraph/filter'] = -> e,m,_ {

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

end
