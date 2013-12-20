watch __FILE__
class E
  
  fn 'req/day',->e,r{
    [303, {'Location'=> e.day.uri + r.q.except('y').qs}, []]}

  def day; as Time.now.strftime '%Y/%m/%d/' end

  fn 'table/month',->d{ m={}
    d.map{|u,r|
      r[Date].do{|d|d[0].do{|t|
          t = Time.parse t unless t.time?
          o=12*t.year + t.month - 1
          x=o/3
          y=o%3
          m[x] ||= {}
          m[x][y] ||= {}
          m[x][y][u] = r
          m[x][y][:time] = t
        }} if r.class==Hash }
    m }

  fn 'table/day',->d{ m={}
    d.map{|u,r|
      r[Date].do{|d|d[0].do{|t|
          t = DateTime.parse t unless t.time?
          w=t.strftime('%Y%W').to_i
          d=t.cwday
          m[w] ||= {}
          m[w][d] ||= {}
          m[w][d][u]  = r
          m[w][d][:time] = t
        }} if r.class==Hash }
    m }

  fn 'table/hour',->d{ m={}
    d.map{|u,r|
      r[Date].do{|d|d[0].do{|t|
          t = Time.parse t unless t.time?
          h=t.hour
          s=h/12
          h12=h%12
          m[h12] ||= {}
          m[h12][s] ||= {}
          m[h12][s][u] = r
          m[h12][s][:time] = t
        }} if r.class==Hash }
    m }

   fn 'view/year',->d,e{F['view/t'][d,e,'month','month']}
  fn 'view/month',->d,e{[{_: :b, c: (d.delete :time).strftime('%B'),style: "color: #{E.cs}"}, F['view/t'][d,e,'day','day']]}
    fn 'view/day',->d,e{[{_: :b, c: (d.delete :time).strftime('%d'),style: "color: #888"},    F['view/t'][d,e,'hour','hour']]}
   fn 'view/hour',->d,e{[{_: :b, c: (d.delete :time).strftime('%H'),style: "float:left"}, F['view/title'][d,e]]}

end
