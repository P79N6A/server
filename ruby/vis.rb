watch __FILE__
class R

  View['d3']   = -> d,e {View['force'][d,e].push H.js('/js/d3')}
  View['cola'] = -> d,e {View['force'][d,e].concat [(H.js '//marvl.infotech.monash.edu/webcola/cola.v3.min'), (H.js '/js/cola')]}

  View['force'] = -> d,e {
    defaultType = SIOC + 'has_parent'
    links = []
    linkType = e.q['link'].do{|a|a.expand} || defaultType # link-type
    d.triples{|s,p,o| # find links
      if (p == linkType || linkType == '*') && o.respond_to?(:uri)
        link = {source: s, target: o.uri}
        d[s][Creator].justArray[0].do{|l| link[:name] = R.mailName l } # human-readable name
        links.push link
      end}
    [(H.css '/css/d3'), (H.js '//d3js.org/d3.v2'), {_: :script, c: "var links = #{links.to_json};"}]}

end
