#watch __FILE__
class R

  View['warp'] = ->graph, env {
    uri = env['SCHEME']+'://linkeddata.github.io/warp/#/list/'+env['SCHEME']+'/'+env['SERVER_NAME']+env['REQUEST_PATH']
    [{_: :noscript, c: View['ls'][graph, env]},
     {_: :script, c: "document.location.href = '#{uri}';"}
    ]}

  View['tabulate'] = ->d=nil,e=nil {
    src = '//linkeddata.github.io/tabulator/'
    [(H.css src + 'tabbedtab'),
     (H.js 'https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min'),
     (H.js src + 'js/mashup/mashlib'),
"<script>jQuery(document).ready(function() {
    var uri = window.location.href;
    window.document.title = uri;
    var kb = tabulator.kb;
    var subject = kb.sym(uri);
    tabulator.outline.GotoSubject(subject, true, undefined, true, undefined);
});</script>",
     {class: :TabulatorOutline, id: :DummyUUID},{_: :table, id: :outline}]}

  View['force'] = -> d,e { # D3.force-directed layout
    links = []
    colors = {}
    defaultType = SIOC + 'has_parent'
    linkType = e.q['link'].do{|a|a.expand} || defaultType
    d.triples{|s,p,o| # each triple in graph
      if (p == linkType || linkType == '*') && o.respond_to?(:uri) # matches specific type or wildcard
        source = s
        target = o.uri
        link = {source: source, target: target}
        d[source].do{|s|s[Creator].justArray[0].do{|l|
            name = l.R.fragment
            link[:sourceName] = name
            link[:sourceColor] = colors[name] ||= cs
         }}
        d[target].do{|t|t[Creator].justArray[0].do{|l|
            name = l.R.fragment
            link[:targetName] = name
            link[:targetColor] = colors[name] ||= cs
          }}
        links.push link
      end}

    [(H.js '//d3js.org/d3.v2'), # D3 library
     {_: :script, c: "var links = #{links.to_json};"}, # graph-arcs to JSON
     H.js('/js/force'),
     H.css('/css/force'),
     H.css('/css/mail'),
     View['HTML'][Hash[d.sort_by{|u,r| # sort graph by date before rendering
                       r.class==Hash ? r[Date].justArray[0].to_s : ''}.reverse],e]]}

end
