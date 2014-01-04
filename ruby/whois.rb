#watch __FILE__
class E

  # shorthand-URL endpoints to look-up people in index

  fn '/whois/GET',->e,r{
    w = (r.q['p']||'').match(/to$/) ? 'to' : 'from'
    [302,{Location: '/'+w+'/'+(URI.escape (r.q['q']||''))},[]]}

  fn '/to/GET',->e,r{
    name = e.pathSegment.uri.sub('/to/','/').tail
    if !name || name.empty?
      false
    else
      H({style: 'text-align: center',
          c: [To.E.rangeP.map(&:uri).grep(/#{name}/).map{|n|
                {_: :a,href: n.E.url+'?set=indexPO&p=sioc:addressed_to', c: n}},
              {_: :style, c: "a {display:block;text-decoration:none}"}]}).hR
    end}

  fn '/from/GET',->e,r{
    name = e.pathSegment.uri.sub('/from/','/').tail
    if !name || name.empty?
      false
    else
      H({style: 'text-align: center',
          c: [Creator.E.rangeP(1e4).map(&:uri).grep(/#{name}/).map{|n|
                {_: :a,href: n.E.url+'?set=indexPO&p=sioc:has_creator', c: n}},
              {_: :style, c: "a {display:block;text-decoration:none}"}]}).hR
    end}
  
end
