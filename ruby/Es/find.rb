#watch __FILE__
class E

  fn 'set/find',->e,q,m,x=''{
    q['q'].do{|q|
      r = '-iregex ' + ('.*' + q + '.*' + x).sh
      s = q['size'].do{|s| s.match(/^\d+$/) && '-size +' + s + 'M'}
      t = q['day'].do{|d| d.match(/^\d+$/) && '-ctime -' + d }
      [e,e.pathSegment].compact.select(&:e).map{|e|
        `find #{e.sh} #{t} #{s} #{r} | head -n 1000`.
        lines.map{|l|l.chomp.unpathURI}}.compact.flatten}}

  fn 'view/find',->i,e{
    {_: :form, method: :GET, action: e['REQUEST_PATH'].t,
      c: [{_: :input, name: :set, value: :find, type: :hidden},
          {_: :input, name: :triplr, value: :id, type: :hidden},
          {_: :input, name: :view, value: :ls, type: :hidden},
          {_: :input, name: :q, style: 'float: left;font-size:1.3em'}]}}

end
