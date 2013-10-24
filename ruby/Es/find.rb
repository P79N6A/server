watch __FILE__
class E

  fn 'set/find',->e,q,m{
    t=q['day'] && q['day'].match(/^\d+$/) && '-ctime -'+q['day']
    s=q['size'] && q['size'].match(/^\d+$/) && '-size +'+q['size']+'M'
    r=q['q'] && '-iregex ' + ('.*'+q['q']+'.*').sh
    [e,e.pathSegment].map{|e|
      `find #{e.sh} #{t} #{s} #{r} | head -n 1024`.lines.map{|l|
        puts "found #{l}"
        l.unpathURI} if e.e}.compact.flatten}

  fn 'view/find',->i,e{
    {_: :form, method: :GET, action: e['REQUEST_PATH'].t,
      c: [{_: :input, name: :set, value: :find, type: :hidden},
          {_: :input, name: :triplr, value: :id, type: :hidden},
          {_: :input, name: :view, value: :ls, type: :hidden},
          {_: :input, name: :q, style: 'float: left;font-size:1.3em'}]}}

end
