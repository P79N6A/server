class R

  TabularView = ViewGroup[Container] = ViewGroup[CSVns+'Row'] = -> g,e {
    e[:color] = R.cs
    keys = g.values.select{|v|v.respond_to? :keys}.map(&:keys).flatten.uniq - [Label] # label used in lieu of URI
    keys = keys - [SIOC+'has_container'] if e.R.path == '/' # hide parent(s) if any on /
    sort = (e.q['sort']||'uri').expand                      # default to URI-sort
    direction = e.q.has_key?('reverse') ? :reverse : :id    # forward or reverse

    # visualize scale on numeric-sorts
    if [Size,Mtime].member? sort
      sizes = g.values.map{|r|r[sort]}.flatten.compact
      range = 0.0
      e[:max] = max = sizes.max.to_f
      e[:min] = min = sizes.min.to_f
      e[:range] = range = max - min if max && min
      e[:scale] = 255.0 / (range && range > 0 && range || 255.0)
    end

    [H.css('/css/table',true), H.css('/css/container',true), "\n", # inline CSS to cut roundtrips
     {_: :style, # add CSS for selected-column
      c: "
table.tab th[property='#{sort}'] {background-color:#{e[:color]}}
table.tab td[property='#{sort}'] {border-style: dotted; border-color: #{e[:color]}; border-width: 0 .1em .1em .1em; padding:0 .2em 0 .2em}
.container a.member:visited {color: #fff;background-color: #{e[:color]}}
"}, "\n",
     {_: :table, :class => :tab, # <table>
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

    TableRow = -> l,e,sort,direction,keys { this = l.uri == e.uri # highlight environment row
      style = if this
                "background-color: #{e[:color]}"
              else
                nil
              end
      bright = :light
      if e[:scale]
        mag = l[sort].justArray[0].do{|s|
          (s - e[:min]) * e[:scale]} || 0
        bright = :dark if mag > 127
        style = "background-color: ##{('%02x' % (255 - mag))*3}" unless this
      end
      [{_: :tr, id: (l.R.fragment||l.uri), class: bright, style: style,
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
