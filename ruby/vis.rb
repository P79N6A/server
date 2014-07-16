watch __FILE__
class R

  View['d3']  = -> d,e {
    View['force'][d,e].
    concat [H.css('/css/d3'), H.js('/js/d3')]}

  View['cola']= -> d,e {
    View['force'][d,e].
    concat [(H.js '//marvl.infotech.monash.edu/webcola/cola.v3.min'),
            (H.js '/js/cola'), H.css('/css/cola'),
            View['HTML'][d,e]]}

  View['force'] = -> d,e {
    links = []
    defaultType = SIOC + 'has_parent'
    linkType = e.q['link'].do{|a|a.expand} || defaultType
    d.triples{|s,p,o| # visit each triple in graph
      if (p == linkType || linkType == '*') && o.respond_to?(:uri) # matches specific type or wildcard
        source = s
        target = o.uri
        link = {source: source, target: target}
        d[source].do{|s|s[Creator].justArray[0].do{|l|link[:sourceName] = R.mailName l}}
        d[target].do{|t|t[Creator].justArray[0].do{|l|link[:targetName] = R.mailName l}}
        links.push link
      end}

    [(H.js '//d3js.org/d3.v2'), {_: :script, c: "var links = #{links.to_json};"}]}

end
