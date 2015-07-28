#watch __FILE__
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
    e.q['addProperty'].do{|p|
      p = p.expand
      keys.push p unless keys.member?(p)||!p.match(/^http/)
    }

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
     {_: :table, :class => :tab, # TABLE
      c: [{_: :tr,
           c: [keys.map{|k|
                 q = e.q.merge({'sort' => k.shorten})
                 if direction == :reverse
                   q.delete 'reverse'
                 else
                   q['reverse'] = ''
                 end
                 [{_: :th, property: k,
                   c: {_: :a, rel: :nofollow, href: CGI.escapeHTML(q.qs), class: Icons[k]||'',
                       c: k == Type ? '' : Icons[k] ? '' : (k.R.fragment||k.R.basename)}}, "\n"]},
               (if e.editable(e.R)
                {_: :th, c: if !e.q.has_key?('edit')
                  {_: :a, class: :wrench, href: '?edit', style: 'color:#aaa'}
                elsif e.q.has_key?('fragment')
                  if !e.q.has_key?('addProperty')
                    {_: :a, class: :addButton, c: '+', title: 'add property', href: e.q.merge({'addProperty' => ''}).qs}
                  elsif e.q['addProperty'].empty?
                    {_: :form, method: :GET,
                     c: [
                       {_: :input, name: :edit, val: :edit, type: :hidden},
                       {_: :input, name: :fragment, val: e.q['fragment'], type: :hidden},
                       {_: :input, name: :addProperty, placeholder: 'add property', style: 'border: .2em solid #0f0;border-radius:.3em;background-color:#dfd;color:#000'}]}
                  end
                  end}
                end)]
          }, "\n",
          ({_: :style, c: rows.map{|r|
              mag = r[sort].justArray[0].do{|s| (s - min) * scale} || 0
              "tr[id='#{r.R.fragment||r.uri}'] td[property='#{sort}'] {color: #{mag < 127 ? :white : :black}; background-color: ##{('%02x' % mag)*3}}\n"}} if scale),
          rows.map{|r|
            TableRow[r,e,sort,direction,keys] # TABLE-ROW
          }]},
     "\n"]}
  
  TableRow = -> l,e,sort,direction,keys {
    this = l.R
    edit = e.q.has_key? 'edit'
    frag = e.q['fragment']
    selURI = if frag
               if e.uri[-1] == '/'
                 e.uri # container
               else
                 e.uri + '#' + frag # resource
               end
             end
    selected = selURI == this.uri
    [(if edit && selected
      [H.css('/css/edit',true), '<form method=POST>']
      end),
     {_: :tr, id: l.uri, href: l.uri, selectable: :true, style: (edit && selected) ? 'background-color:#f6f6f6;color:#000' : '',
      c: ["\n",
          keys.map{|k|
            [{_: :td, property: k,
              c: if edit && selected
               (l[k]||'').justArray.map{|o|
                 EditableValue[k,o,e]}
             else
               case k
               when 'uri'
                 {_: :a, href: (CGI.escapeHTML l.uri),
                  c: (l[Title]||l[Label]||this.basename).justArray[0]} if l.uri
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
                    (if e.editable this
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
               end
              end}, "\n"]
          },
          if edit
            {_: :td, c: if selected
              SaveButton[e]
            else
              {_: :a, class: :wrench, style: 'color:#888',href: this.docroot.uri+'?edit&fragment='+(this.fragment||'')}
             end}
          end]},
     ('</form>' if edit && selected),
     l[Content].do{|c|{_: :tr, c: {_: :td, class: :content, colspan: keys.size, c: c}}}]}

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
