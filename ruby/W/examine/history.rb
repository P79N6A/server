#watch __FILE__
class E

  F["?"]||={}
  F["?"].update({'taft'=>{
               'triplr'=>'triplrMozHist',
                 'view'=>'page',
                    'v'=>'timegraph',
                'label'=>'uri',
                  'arc'=>'referer'}})

  def triplrMozHist
    c = @r.q['c'].do{|c|c.match(/[0-9]+/) && c } || '32'
    q = @r.q['q'].do{|m|m.match(/^[a-zA-Z0-9\-_\.\/]+$/) &&
        "and p.url like '%#{m}%'"}
    t = @r.q['t'].do{|t| "and h.visit_date < #{Time.parse(t).to_f*1e6}"}

    query = "select p.url, pr.url, h.visit_date, hr.visit_date from moz_places as p, moz_places as pr, moz_historyvisits as h, moz_historyvisits as hr where p.id = h.place_id and pr.id = hr.place_id and hr.id = h.from_visit #{q} #{t} order by h.visit_date desc limit #{c}"

    `sqlite3 -separator "\t" #{sh} "#{query}"`.
      lines.to_a.map{|i| # each line
      i = i.split /\t/   # fields
      # 0 URL
      # 1 Referer URL
      # 2 visit-date
      # 3 Referer visit-date
      yield i[0], Date, Time.at(i[2].to_f/1e6)
      yield i[1], Date, Time.at(i[3].to_f/1e6)
      yield i[0],'referer',i[1].E }

    yield 'prev','url',@r['REQUEST_PATH']
  end
end
