class E

  fn 'set/find',->e,q,m{
    t=q['day'] && q['day'].match(/^\d+$/) && '-ctime -'+q['day']
    s=q['size'] && q['size'].match(/^\d+$/) && '-size +'+q['size']+'M'
    r=q['q'] && '-iregex ' + ('.*'+q['q']+'.*').sh
    `find #{e.sh} #{t} #{s} #{r}`.lines.map{|p|p[Blen+1..-1].unpath}}

end
