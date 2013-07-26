#watch __FILE__
class E
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
              [s,
               Date,
               Time.parse(o).utc.iso8601] :[s,p,o])} end

    fn 'cal/day',->{Time.now.strftime '%Y/%m/%d/'}
  fn 'cal/month',->{Time.now.strftime '%Y/%m/'}

  # y=day forwards to current day's directory
  %w{day month}.map{|i|
    fn 'req/'+i,->e,r{
      [303,{'Location'=>e.send(i).uri+r.q.except('y').qs},[]]}}
    
    def day; as Fn 'cal/day' end
  def month; as Fn 'cal/month' end

  fn 'graph/cal',->d,e,m{
    DateTime.parse(e['s']||'2011-03-03').
     upto(e['f'].do{|f|DateTime.parse f} || DateTime.now).
     map{|d|m[d.iso8601]={Date=>[d]}}
    m }

  fn 'table/year',->d{ m={}
    d.map{|u,r|
      r[Date][0].do{|t|
        t = Time.parse t unless t.time?
        o=12*t.year + t.month - 1
        x=o/3
        y=o%3
        m[x] ||= {}
        m[x][y] ||= {}
        m[x][y][u] = r
        m[x][y][:t] = t
      }}
    m }

  fn 'table/day',->d{ m={}
    d.map{|u,r|
      r[Date][0].do{|t|
        t = Time.parse t unless t.time?
        h=t.hour
        s=h/12
        h12=h%12
        m[h12] ||= {}
        m[h12][s] ||= {}
        m[h12][s][u] = r
        m[h12][s][:t] = t
      }}
    m }

  fn 'table/month',->d{ m={}
    d.map{|u,r|
      r[Date][0].do{|t|
        t = DateTime.parse t unless t.time?
        w=t.strftime('%Y%W').to_i
        d=t.cwday
        m[w] ||= {}
        m[w][d] ||= {}
        m[w][d][u]  = r
        m[w][d][:t] = t
      }}
  m }

  fn 'view/year',->d,e{[(H.css '/css/cal'),(Fn 'view/t',d,e,'year','month.label')]}
  fn 'view/month',->d,e{Fn 'view/t',d,e,'month','day.label'}
  fn 'view/day',->d,e{Fn 'view/t',d,e,'day','hour'}

  fn 'view/hour',->d,e{
    t = d.delete :t
    {style: 'background-color:#'+(t.hour % 2 == 1 ? 'ccc' : 'fff'),c:[{_:  :b,style:'float:left;font-size:1.3em', c: [t.hour==0 && {_: :span, style: 'font-size:.8em;color:white;background-color:#ff%02xff' % rand(256),c: t.strftime('%e %B')},t.hour]},
     (Fn 'view/'+(e.q['hourv']||'title'),d,e)
    ]}}

  fn 'view/month.label',->d,e{
    t = d.delete :t
    {class: :month, style: 'background-color:#bb%02xff'%(rand(64)+192), c:
      ['<b>',(t.month==1 && ['<span class=year>',t.year,'</span> ']),t.strftime('%B'),'</b>',(Fn 'view/'+(e.q['monthv']||'month'),d,e)]}}

  fn 'view/day.label',->d,e{
    t = d.delete :t
       e[:m]||={}
    c=(e[:m][t.month]||='00%02xff' % (64+rand(192)))
    {style: 'padding:.4em;background-color:#'+c,c:[{_: :b,property: Date, c: [t.day, t.day==1 && {_: :span, style: 'font-size:.5em',c: t.strftime('%b')}]},
     (Fn 'view/'+(e.q['dayv']||'title'),d,e)
    ]}}

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
