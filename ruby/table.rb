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

  ViewGroup[Container] = -> g,e {
    tabular = e.q['table'] == 'table'
    if tabular
      TabularView[g,e]
    else
      g.map{|id,container|
        {class: :container,
         c: [{class: :label, c: {_: :a, href: id+'?set=first-page', c: id.R.basename}},
             {class: :contents,
              c: TabularView[{id => container},e,['uri',Type,Mtime,SIOC+'has_container',Size]]
             }]}}
    end}

  TabularView = ViewGroup[Directory] = ViewGroup[Stat+'File'] = ViewGroup[Resource] = ViewGroup[CSVns+'Row'] = -> g, e, skipP = nil {

    sort = (e.q['sort']||'uri').expand                      # sort property
    direction = e.q.has_key?('reverse') ? :reverse : :id    # sort direction

    keys = g.values.select{|v|v.respond_to? :keys}.map(&:keys).flatten.uniq # base keys
    keys = keys - [Title, Label, Content, Image]
    keys = keys - skipP if skipP                 # key-skiplist
    rows = g.resources(e).send direction                    # sorted resources
    e.q['addProperty'].do{|p|
      p = p.expand
      keys.push p unless keys.member?(p)||!p.match(/^http/)
    }

    {_: :table, class: :tab,
     c: [({_: :thead,
           c: {_: :tr,
               c: [keys.map{|k|
                     q = e.q.merge({'sort' => k.shorten})
                     if direction == :reverse
                       q.delete 'reverse'
                     else
                       q['reverse'] = ''
                     end
                     [{_: :th,
                       property: k,
                       style: k == sort ? 'background-color:#0f0' : '',
                       c: {_: :a,
                           rel: :nofollow,
                           href: CGI.escapeHTML(q.qs),
                           class: Icons[k]||'',
                           c: k == Type ? '' : Icons[k] ? '' : (k.R.fragment||k.R.basename)}}, "\n"]},
                   (if e.editable(e.R)
                    {_: :th, c: if !e.q.has_key?('edit')
                      {_: :a, class: :wrench, href: '?edit', style: 'color:#aaa'}
                    elsif e.q.has_key?('fragment')
                      if !e.q.has_key?('addProperty')
                        {_: :a, class: :addButton, c: '+', title: 'add property', href: e.q.merge({'addProperty' => ''}).qs}
                      elsif e.q['addProperty'].empty?
                        {_: :form, method: :GET,
                         c: [{_: :input, name: :edit, val: :edit, type: :hidden},
                             {_: :input, name: :fragment, val: e.q['fragment'], type: :hidden},
                             {_: :input, name: :addProperty, placeholder: 'add property'}]}
                      end
                     end}
                    end)]}} unless skipP),
         {_: :tbody, c: rows.map{|r| TableRow[r,e,sort,direction,keys]}}]}}

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
     {_: :tr, id: rand.to_s.h, href: l.uri, selectable: :true, style: (edit && selected) ? 'background-color:#f6f6f6;color:#000' : '',
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
                  c: CGI.escapeHTML((l[Title]||l[Label]||this.basename).justArray[0])} if l.uri
               when Type
                 l[Type].justArray.map{|t|
                   icon = Icons[t.uri]
                   [({_: :a, href: CGI.escapeHTML(l.uri), c: icon ? '' : (t.R.fragment||t.R.basename), class: icon} if l.uri),
                    (if e.editable this
                     Containers[t.uri].do{|c|
                       n = c.R.fragment
                       {_: :a, href: l.uri+'?new', c: '+', class: :new, title: "new #{n} in #{l.uri}"}}
                     end)]}
               when LDP+'contains'
                 l[k].do{|children|
                   children = children.justArray
                   if e.q['table'] == 'table' || children[0].keys.size>1
                     cGraph = {}
                     children.map{|c| cGraph[c.uri] = c }
                     ViewGroup[CSVns+'Row'][cGraph,e,[Date,SIOC+'has_container']]
                   else
                     children.map{|c|c.R}
                   end
                 }
               when WikiText
                 Render[WikiText][l[k]]
               when DC+'tag'
                 l[k].justArray.map{|v|
                   e[:label][v] = true
                   [{_: :a, href: '#', name: v, c: v},' ']}
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
     l[Content].do{|c|{_: :tr, c: {_: :td, class: :content, colspan: keys.size, c: c}}},
     l[Image].do{|c|
       {_: :tr,
        c: {_: :td, colspan: keys.size,
            c: c.justArray.map{|i|{_: :a, href: l.uri, c: {_: :img, src: i.uri, class: :tablePreview}}}.intersperse(' ')}}},
    ]}

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
