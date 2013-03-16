class E
#watch __FILE__
  def json
    yield uri, '/application/json', (JSON.parse read) if e
  end
  graphFromStream :json

  fn 'view/application/json',->m,e{
    m.map{|u,j|
      e.q['sel'].do{|s|
        c = j['/application/json'][0]
        s.split(/\./).map{|s|
          s = s.to_i if s.match(/^\d$/)
          c = c[s] }
        [{_: :a,
           href: u+'?q=json&view=application/json&sel='+s,
           c: {_: :b, c: u+'#'+s}}, c.html]
      }||[{_: :h3, c: u},j.html]}}
  
  def to_json *a
    to_h.to_json *a
  end

  fn Render+'application/json',->d,_=nil{[d].to_json}

end
