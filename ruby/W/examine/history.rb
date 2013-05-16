class E
 
  F["?"]||={}
  F["?"].update({'taft'=>{
                'graph'=>'|',
                    '|'=>'mozHistory',
                 'view'=>'page',
                    'v'=>'tg',
                  'arc'=>'referer',
                'label'=>'uri'}})

  def mozHistory
    c = @r.q['c'].match(/[0-9]+/) ? @r.q['c'] : '18'
    q = @r.q['match'].do{|m|m.match(/[a-zA-Z\-_\.\/]+/) && "and p.url like '#{@r.q.has_key?('full')?'':'%'}#{m}%'"}
    t = @r.q['t'].do{|t| "and h.visit_date < #{Time.parse(t).to_f*1e6}"}

    `sqlite3 -separator "\t" #{sh} "select p.url, r.url, h.visit_date, hr.visit_date from moz_places as p,moz_places as r, moz_historyvisits as h, moz_historyvisits as hr where p.id = h.place_id and r.id = hr.place_id and hr.id = h.from_visit #{q} #{t} order by h.visit_date desc limit #{c}"`.lines.to_a.map{|i|i.split "\t"}.do{|l|

      yield 'prev','url',@r['REQUEST_PATH']
      yield 'prev','t',Time.at(l[-1][2].to_f/1e6).iso8601

      l.map{|i|
        yield i[0], Date, Time.at(i[2].to_f/1e6)
        yield i[1], Date, Time.at(i[3].to_f/1e6)
        yield i[0],'referer',i[1].E }

    } end
end
