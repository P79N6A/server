watch __FILE__
class E


  def triplrMozHist
    c = @r.q['c'].match(/[0-9]+/) ? @r.q['c'] : '18'
    q = @r.q['q'].do{|m|m.match(/[a-zA-Z\-_\.\/]+/) &&
        "and p.url like '#{@r.q.has_key?('full')?'':'%'}#{m}%'"}
    t = @r.q['t'].do{|t| "and h.visit_date < #{Time.parse(t).to_f*1e6}"}

    query = "select p.url, pr.url, h.visit_date, hr.visit_date from moz_places as p, moz_places as pr, moz_historyvisits as h, moz_historyvisits as hr where p.id = h.place_id and pr.id = hr.place_id and hr.id = h.from_visit #{q} #{t} order by h.visit_date desc limit #{c}"

    # 0 URL
    # 1 Referer URL
    # 2 visit-date
    # 3 Referer visit-date

    `sqlite3 -separator "\t" #{sh} "#{query}"`.
      lines.to_a.map{|i| # each line
      i = i.split /\t/   # fields
      yield i[0], Date, Time.at(i[2].to_f/1e6)
      yield i[1], Date, Time.at(i[3].to_f/1e6)
      yield i[0],'referer',i[1].E }

    yield 'prev','url',@r['REQUEST_PATH'] # base URI doesn't change as it's SQLite file
  end
end
