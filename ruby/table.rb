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

  TabularView =  ViewGroup[Directory] = ViewGroup[Container] = ViewGroup[Stat+'File'] = ViewGroup[Resource] = ViewGroup[CSVns+'Row'] = -> g, e, skipP = nil {
    containers = g.values

    # move contained-nodes from toplevel to child-position
    containers.map{|c|
      c[LDP+'contains'] = c[LDP+'contains'].justArray.map{|child|
        if g[child.uri] # contained node
          g.delete child.uri
        else
          child
        end
      } if c.class == Hash && c[LDP+'contains']
    }

    sort = (e.q['sort']||'uri').expand                      # default to URI-sort
    direction = e.q.has_key?('reverse') ? :reverse : :id    # sort direction

    keys = g.values.select{|v|v.respond_to? :keys}.map(&:keys).flatten.uniq # base keys
    keys = keys - [Title, Label, Content, Image]            # title/labels on URI, content gets own row
    keys = keys - (skipP - [sort]) if skipP                 # arbitrary key-skiplist
    
    rows = g.resources(e).send direction                    # sorted resources
    e.q['addProperty'].do{|p|
      p = p.expand
      keys.push p unless keys.member?(p)||!p.match(/^http/)
    }

    if keys.size == 1 && keys[0] == 'uri'
      g.keys.map{|r|[r.R,' ']}
    else

      if [Size,Mtime].member? sort
        sizes = g.values.map{|r|r[sort]}.flatten.compact
        range = 0.0
        max = sizes.max.to_f
        min = sizes.min.to_f
        range = max - min if max && min
        scale = 255.0 / (range && range > 0 && range || 255.0)
      end

      {_: :table, :class => :tab, # TABLE
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
                         style: k == sort ? 'background-color:#555' : '',
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
                           c: [
                             {_: :input, name: :edit, val: :edit, type: :hidden},
                             {_: :input, name: :fragment, val: e.q['fragment'], type: :hidden},
                             {_: :input, name: :addProperty, placeholder: 'add property', style: 'border: .2em solid #0f0;border-radius:.3em;background-color:#dfd;color:#000'}]}
                        end
                       end}
                      end)]}} unless skipP),
           ({_: :style, c: rows.map{|r|
               mag = r[sort].justArray[0].do{|s| (s - min) * scale} || 0
               "tr[href='#{r.R.fragment||r.uri}'] > td[property='#{sort}'] {color: #{mag < 127 ? :white : :black}; background-color: ##{('%02x' % mag)*3}}\n"}} if scale),
           {_: :tbody, c: rows.map{|r|
              TableRow[r,e,sort,direction,keys] # TABLE-ROW
            }}]}
    end}
  
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
                  c: (l[Title]||l[Label]||this.basename).justArray[0]} if l.uri
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
                   cGraph = {}
                   children.justArray.map{|c|
                     cGraph[c.uri] = c
                   }
                   ViewGroup[CSVns+'Row'][cGraph,e,[Date,SIOC+'has_container']]}
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
            c: c.justArray.map{|i|{_: :a, href: i.uri, c: {_: :img, src: i.uri, class: :tablePreview}}}.intersperse(' ')}}},
    ]}

  GET['/tabulator'] = -> r,e {[200, {'Content-Type' => 'text/html'},[Render['text/html'][{}, e, Tabulator]]]}

  Tabulator = -> g,e { # data browser/editor https://github.com/linkeddata/tabulator.git
    path = e.R.path

    # bind subject URI
    subject = if path.match(/^\/tabulator/) # tabulator-UI for another URI (XHR + CORS permissions required)
                e.scheme + ':' + path.sub(/^\/tabulator/,'/')
              else # this URI
                e.uri
              end
     # TODO import new jquery-free version
    # prioritize local script-cache
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
