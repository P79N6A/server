#watch __FILE__
class E

  fn 'set/find',->e,q,m{
    t=q['day'] && q['day'].match(/^\d+$/) && '-ctime -'+q['day']
    s=q['size'] && q['size'].match(/^\d+$/) && '-size +'+q['size']+'M'
    r=q['q'] && '-iregex ' + ('.*'+q['q']+'.*').sh
    `find #{e.sh} #{t} #{s} #{r} | head -n 1024`.lines.map &:unpathURI}
  
  fn 'graph/find',->e,q,m{
    (Fn 'set/find', e,q,m).do{|f|
      if f.size < 256
        f.map{|r|r.fromStream m,:triplrInode,false}
      else
        f.map{|r|m[r.uri]=r}
      end}}

  fn 'view/find',->i,e{
    {_: :form, method: :GET, action: e['REQUEST_PATH'].t, style: 'float: right',
      c: [{_: :input, name: :graph, value: :find, type: :hidden},
          {_: :input, name: :view, value: :ls, type: :hidden},
          {_: :input, name: :q}]}}

end
