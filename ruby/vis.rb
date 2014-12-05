#watch __FILE__
class R

  ViewA['#tabulator'] = -> r,e {
    src = '//linkeddata.github.io/tabulator/'
    [(H.js 'https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min'),
     (H.js  src + 'js/mashup/mashlib'),
     (H.js  '/js/tabr'),
     (H.css src + 'tabbedtab'),
     {class: :TabulatorOutline, id: :DummyUUID},{_: :table, id: :outline}]}

  ViewA['#d3_force'] = -> r,e {
    links = []
    colors = {}
    defaultType = SIOC + 'has_parent'
    linkType = e.q['link'].do{|a|a.expand} || defaultType
    d.triples{|s,p,o| # each triple in graph
      if p == linkType && o.respond_to?(:uri)
        source = s
        target = o.uri
        link = {source: source, target: target}
        d[source].do{|s|
          s[Creator].justArray[0].do{|l|
            name = l.R.fragment
            link[:sourceName] = name unless colors[name]
            link[:sourceColor] = colors[name] ||= cs
         }}
        d[target].do{|t|
          t[Creator].justArray[0].do{|l|
            name = l.R.fragment
            link[:targetName] = name unless colors[name]
            link[:targetColor] = colors[name] ||= cs
          }}
        links.push link
      end}
    
    e[:container] = false # don't summarize/reduce content
    hide = e.q['view'] == 'unquote'

    [(H.js '//d3js.org/d3.v2'), # D3 library
     {_: :script, c: "var links = #{links.to_json};"}, # graph-arcs to JSON
     H.js('/js/force',true), H.css('/css/force',true), H.css('/css/mail',true),
     {_: :a, href: hide ? '?' : '?view=noquote', c: hide ? '&gt;' : '&lt;', title: "#{hide ? 'show' : 'hide'} quotes", style: 'position: fixed; top: .2em; right: .2em; z-index: 2; border-radius: .1em; font-size: 2.3em; color: #bbb; background-color: #fff; border: .05em dotted #bbb'},
     HTMLr[Hash[d.sort_by{|u,r| # sort graph by date before rendering
                       r.class==Hash ? r[Date].justArray[0].to_s : ''}.reverse],e]]}

end
