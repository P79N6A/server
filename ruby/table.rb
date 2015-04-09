class R

  TabularView = ViewGroup[Container] = ViewGroup[CSVns+'Row'] = -> g,e {
    keys = g.values.select{|v|v.respond_to? :keys}.map(&:keys).flatten.uniq - [Label]
    keys = keys - [SIOC+'has_container'] if e.R.path == '/'
    sort = (e.q['sort']||'uri').expand
    direction = e.q.has_key?('reverse') ? :reverse : :id
    sizes = g.values.map{|r|r[Size]}.flatten.compact
    e[:max] = size = sizes.max
    e[:color] = R.cs
    e[:scale] = 255.0 / (size && size > 0 && size || 255).to_f

    [H.css('/css/table',true), H.css('/css/container',true), "\n",
     {_: :style, c: "
table.tab th[property='#{sort}'] {background-color:#{e[:color]}}
table.tab td[property='#{sort}'] {border-style: solid; border-color: #{e[:color]}; border-width: 0 0 0 .1em; padding:0 .2em 0 .2em}
"}, "\n",
     {_: :table, :class => :tab,
      c: [{_: :tr,
           c: keys.map{|k|
             q = e.q.merge({'sort' => k.shorten})
             if direction == :reverse
               q.delete 'reverse'
             else
               q['reverse'] = ''
             end
             [{_: :th, property: k,
               c: {_: :a, rel: :nofollow, href: CGI.escapeHTML(q.qs), class: Icons[k]||'',
                   c: if Type == k
                    {_: :img, src: '/css/misc/cube.svg'}
                  elsif Icons[k]
                    ''
                  else
                    k.R.abbr
                   end
                  }}, "\n"]}}, "\n",
          g.resources(e).send(direction).map{|row|
            TableRow[row,e,sort,direction,keys]}]}, "\n"]}

    TableRow = -> l,e,sort,direction,keys {
    mag = l[Size].justArray[0].do{|s|s * e[:scale]} || 0
    c = '%02x' % (255 - mag)
    color = mag > 127 ? :dark : :light
    this = l.uri == e.uri # environment URI
    [{_: :tr, id: (l.R.fragment||l.uri), class: color, style: "background-color: #{this ? e[:color] : ('#'+c*3)}",
      c: ["\n",
          keys.map{|k|
            [{_: :td, property: k,
              c: case k
                 when 'uri'
                   {_: :a, href: (CGI.escapeHTML l.uri),
                    c: (CGI.escapeHTML (l[Title] || l[Label] ||l.R.basename).justArray[0])}
                 when Type
                   l[Type].justArray.map{|t|
                     icon = Icons[t.uri]
                     href = if t.uri == Directory
                              res = l.R
                              e.scheme + '://linkeddata.github.io/warp/#/list/' + e.scheme + '/' + res.host + res.path
                            else
                              l.uri
                            end
                     [{_: :a, href: CGI.escapeHTML(href), c: icon ? '' : (t.R.fragment||t.R.basename), class: icon},
                      Containers[t.uri].do{|c|
                         n = c.R.fragment
                         {_: :a, href: l.uri+'?new', c: '+', class: :new, title: "new #{n} in #{l.uri}"}
                      }]}
                 when LDP+'contains'
                   ViewA[Container][l,e,sort,direction]
                 when WikiText
                   Render[WikiText][l[k]]
                 else
                   l[k].justArray.map{|v|
                     case v
                     when Hash
                       v.R
                     else
                       v
                     end
                   }
                 end}, "\n"]
          }]}, "\n"]}

  ViewGroup[Directory] = ViewGroup[Stat+'File'] = ViewGroup[Resource] = TabularView

  GET['/tabulator'] = -> r,e {[200, {'Content-Type' => 'text/html'},[Render['text/html'][{}, e, Tabulator]]]}

  Tabulator = -> g,e { src = e.scheme+'://linkeddata.github.io/tabulator/'
    [(H.js 'https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min'),
     (H.js  src + 'js/mashup/mashlib'),
     (H.css src + 'tabbedtab'),
     {_: :script, c: "
document.addEventListener('DOMContentLoaded', function(){
    var kb = tabulator.kb;
    var subject = kb.sym('#{e.scheme+':' + e.R.path.sub(/^\/tabulator/,'/')}');
    tabulator.outline.GotoSubject(subject, true, undefined, true, undefined);
}, false);"}, {class: :TabulatorOutline, id: :DummyUUID},{_: :table, id: :outline}]}

end
