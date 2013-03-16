#watch __FILE__
class E

  fn 'view/scale',->d,e{
    i=F['view/scale/item']
    Fn 'view/scale/base',d,e,->{d.map{|u,r|i.(r,e)}}}

  fn 'view/scale/base',->d,e,c{
    e[:scale] = e.q['a'].expand
    e[:v]={Date => ->t{
       t.time? ? t : Time.parse(t)
      }}[e[:scale]]||->a{a}
    vs=d.map{|_,r|r[e[:scale]]}.flatten.compact.
        map{|v| e[:v].(v)}.
        map &:to_f
    e[:max] = vs.max
    e[:min] = vs.min
    e[:scalev] = 100/(e[:max] - e[:min])
    [H.css('/css/scale'),H.js('/js/scale'),
     {id: :scale, c: c.()},
     {id: :space},
     (Fn 'view/'+e.q['scalev'],d,e)]}

  fn 'view/scale/item',->r,x{
    [*r[x[:scale]]][0].do{|v|
      v = x[:v].(v).to_f
     {_: :a, href: '#'+r.uri, title: v.to_s+' '+r.uri,
        c: {class: :bar, style:"left:#{(v-x[:min])*x[:scalev]}%"}}}}

end
