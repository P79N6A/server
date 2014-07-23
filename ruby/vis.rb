#watch __FILE__
class R

  View['force'] = -> d,e {
    links = []
    colors = {}
    defaultType = SIOC + 'has_parent'
    linkType = e.q['link'].do{|a|a.expand} || defaultType
    d.triples{|s,p,o| # visit each triple in graph
      if (p == linkType || linkType == '*') && o.respond_to?(:uri) # matches specific type or wildcard
        source = s
        target = o.uri
        link = {source: source, target: target}
        d[source].do{|s|s[Creator].justArray[0].do{|l|
            name = R.mailName l
            link[:sourceName] = name
            link[:sourceColor] = colors[name] ||= cs
         }}
        d[target].do{|t|t[Creator].justArray[0].do{|l|
            name = R.mailName l
            link[:targetName] = name
            link[:targetColor] = colors[name] ||= cs
          }}
        links.push link
      end}

    [(H.js '//d3js.org/d3.v2'),
     {_: :script, c: "var links = #{links.to_json};"},
     H.js('/js/d3'),
     H.css('/css/d3'),
     View['HTML'][Hash[d.sort_by{|u,r|r.class==Hash ? r[Date].justArray[0].to_s : ''}.reverse],e]]}

end
