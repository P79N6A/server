watch __FILE__
class R

  View['d3'] = -> d,e {
    links = []
    link = e.q['link'] || SIOC+'has_parent' # link predicate
    d.triples{|s,p,o| # find links
      if p == link && o.respond_to?(:uri)
        name = d[s][Creator].justArray[0].do{|l| R.mailName l } || s
        links.push({source: s, target: o.uri, name: name})
      end}
    [(H.css '/css/d3'), (H.js '//d3js.org/d3.v2'), {_: :script, c: "var links = #{links.to_json};"},
     (H.js '/js/d3')]}

end
