watch __FILE__
class R

  def triplrCSV d
    lines = begin
              CSV.read pathPOSIX
            rescue
              puts "CSV parse-error in #{uri}"
              []
            end
    lines[0].do{|fields| # header-row
      yield uri+'#', Type, R[CSVns+'Table']
      yield uri+'#', CSVns+'rowCount', lines.size
      lines[1..-1].each_with_index{|row,line|
        row.each_with_index{|field,i|
          id = uri + '#row:' + line.to_s
          yield id, fields[i], field
          yield id, Type, R[CSVns+'Row']}}}
  end

  TabularView = ViewGroup[Container] = ViewGroup[CSVns+'Row'] = -> g,e {
    color = e[:color]
    keys = g.values.select{|v|v.respond_to? :keys}.map(&:keys).flatten.uniq -
           [Label,
            Content,
            Atom+'media']
    keys = keys - [SIOC+'has_container'] if e.R.path == '/' # hide parent-column on root container
    sort = (e.q['sort']||'uri').expand                      # default to URI-sort
    direction = e.q.has_key?('reverse') ? :reverse : :id    # sort direction
    rows = g.resources(e).send direction                    # sorted resources

    # scale numeric-sort fields
    if [Size,Mtime].member? sort
      sizes = g.values.map{|r|r[sort]}.flatten.compact
      range = 0.0
      max = sizes.max.to_f
      min = sizes.min.to_f
      range = max - min if max && min
      scale = 255.0 / (range && range > 0 && range || 255.0)
    end

    [H.css('/css/table',true), "\n",
     {_: :style, # highlight selected property (column) and resource (row)
      c: "td[property='#{sort}'] {background-color: #{color};color:#fff}
tr[id='#{e.uri}'] td {background-color:#000}
tr[id='#{e.uri}'] td a, td[property='#{sort}'] a {color:#fff}
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
                   c: k == Type ? '' : Icons[k] ? '' : (k.R.fragment||k.R.basename)}}, "\n"]}}, "\n",
          ({_: :style, c: rows.map{|r|
              mag = r[sort].justArray[0].do{|s| (s - min) * scale} || 0
              "tr[id='#{r.R.fragment||r.uri}'] td[property='#{sort}'] {color: #{mag < 127 ? :white : :black}; background-color: ##{('%02x' % mag)*3}}\n"}} if scale),
          rows.map{|r|
            TableRow[r,e,sort,direction,keys]
          }]},
     "\n"]}

    TableRow = -> l,e,sort,direction,keys {
      [{_: :tr, id: (l.R.fragment||l.uri),
        c: ["\n",
         keys.map{|k|
              [{_: :td, property: k,
              c: case k
                 when 'uri'
                   {_: :a, href: (CGI.escapeHTML l.uri),
                    c: (l[Title]||l[Label]||l.R.basename).justArray[0]} if l.uri
                 when Type
                   l[Type].justArray.map{|t|
                     icon = Icons[t.uri]
                     href = if t.uri == Directory
                              res = e.R.join l.uri
                              e.scheme + '://linkeddata.github.io/warp/#/list/' + e.scheme + '/' + res.host + res.path
                            else
                              l.uri
                            end
                     [({_: :a, href: CGI.escapeHTML(href), c: icon ? '' : (t.R.fragment||t.R.basename), class: icon} if href),
                      (if e.editable l.R
                       Containers[t.uri].do{|c|
                         n = c.R.fragment
                         {_: :a, href: l.uri+'?new', c: '+', class: :new, title: "new #{n} in #{l.uri}"}}
                       end)]}
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
                   }.intersperse(' ')
                 end}, "\n"]
            },
         (if e.q.has_key? 'edit'
          {_: :td, c: {_: :a, class: :cog, href: '?edit'}
           }
          end)
           ]}, "\n",
       l[Content].do{|c|
         {_: :tr, c: {_: :td, class: :content, colspan: keys.size, c: c}}
       }]}

    ViewGroup[Directory] = ViewGroup[Stat+'File'] = TabularView
    ViewGroup[Resource] = TabularView

  GET['/tabulator'] = -> r,e {[200, {'Content-Type' => 'text/html'},[Render['text/html'][{}, e, Tabulator]]]}

  Tabulator = -> g,e { # data browser/editor https://github.com/linkeddata/tabulator.git
    path = e.R.path

    # select subject URI
    subject = if path.match(/^\/tabulator/) # tabulator-UI for another URI (XHR + CORS)
                e.scheme + ':' + path.sub(/^\/tabulator/,'/')
              else # this URI
                e.uri
              end

    # prefer local script caches
    jquery = if '/js/jquery.js'.R.exist?
               '/js/jquery'
             else
               'https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min'
             end
    tabr = if '/tabulator/js/mashup/mashlib.js'.R.exist?
             '/tabulator'
           else
             e.scheme + '://linkeddata.github.io/tabulator'
           end

    [(H.js jquery), (H.js tabr + '/js/mashup/mashlib'),
     (H.css tabr + '/tabbedtab'),
     {_: :script, c: "
document.addEventListener('DOMContentLoaded', function(){
    var kb = tabulator.kb;
    var subject = kb.sym('#{subject}');
    tabulator.outline.GotoSubject(subject, true, undefined, true, undefined);
}, false);"},
     {class: :TabulatorOutline, id: :DummyUUID},
     {_: :table, id: :outline}]}

  # tabular view for schema types
  ViewGroup[RDFClass] =
    ViewGroup[RDFs+'Datatype'] =
    ViewGroup[Property] =
    ViewGroup[OWL+'Class'] =
    ViewGroup[OWL+'Ontology'] =
    ViewGroup[OWL+'ObjectProperty'] =
    ViewGroup[OWL+'DatatypeProperty'] =
    ViewGroup[OWL+'SymmetricProperty'] =
    ViewGroup[OWL+'TransitiveProperty'] =
    TabularView

end
