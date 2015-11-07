# -*- coding: utf-8 -*-
#watch __FILE__

def H x # Ruby values to HTML
  case x
  when Hash # Hash as DOM-node
    void = [:img, :input, :link, :meta].member? x[:_]
    '<' + (x[:_] || 'div').to_s +                        # name
      (x.keys - [:_,:c]).map{|a|                         # attribute name
      ' ' + a.to_s + '=' + "'" + x[a].to_s.chars.map{|c| # attribute value
        {"'"=>'%27',
         '>'=>'%3E',
         '<'=>'%3C'}[c]||c}.join + "'"}.join +
      (void ? '/' : '') + '>' + (H x[:c]) +              # children or void
      (void ? '' : ('</'+(x[:_]||'div').to_s+'>'))       # closer
  when R # resource
    H x.href
  when TrueClass
    '<input type="checkbox" title="True" checked="checked"/>'
  when FalseClass
    '<input type="checkbox" title="True"/>'
  when String
    x
  when Symbol
    x.to_s
  when Array
    x.map{|n|H n}.join
  when Float
    x.to_s
  when Bignum
    x.to_s
  when Fixnum
    x.to_s
  when NilClass
    ''
  when StringIO
    'StringIO'
  when IO
    'IO'
  when Method
    'function'
  when EventMachine::DefaultDeferrable
    'event'
  else
    puts ["undefined HTML-serialization for",x.class].join ' '
    x.to_s.noHTML
  end
end

class H

  def H.[] h; H h end

  def H.js a,inline=false # script tag
    p = a + '.js'
    inline ? {_: :script, c: p.R.r} :
    {_: :script, type: "text/javascript", src: p}
  end

  def H.css a,inline=false # stylesheet
    p = a + '.css'
    inline ? {_: :style, c: p.R.r} :
    {_: :link, href: p, rel: :stylesheet, type: R::MIME[:css]}
  end

end

class R

  def href name = nil
    {_: :a, href: uri, c: name || fragment || basename}
  end

  begin
    require 'nokogiri'
  rescue LoadError
    puts "warning: nokogiri missing"
  end

  def nokogiri
    Nokogiri::HTML.parse (open uri).read
  end

  StripHTML = -> body, loseTags=%w{script style}, keepAttr=%w{alt href rel src title type} {
    begin
      html = Nokogiri::HTML.fragment body
      loseTags.map{|tag| html.css(tag).remove } if loseTags
      html.traverse{|e|e.attribute_nodes.map{|a|a.unlink unless keepAttr.member? a.name}} if keepAttr
      html.to_xhtml
    rescue
      ""
    end}

  Render['text/html'] = -> d,e,view=nil {
    H ["<!DOCTYPE html>\n",
       {_: :html,
        c: [{_: :head,
             c: [{_: :meta, charset: 'utf-8'},
                 {_: :link, rel: :icon, href: '/.icon.png'},
                 {_: :link, rel: :parent, href: e.R.parentURI},
                 e[:title].do{|t|{_: :title, c: CGI.escapeHTML(t)}},
                 e[:Links].do{|links|
                   links.map{|type,uri|
                     {_: :link, rel: type, href: CGI.escapeHTML(uri.to_s)}}},
                 H.css('/css/base',true)]},
            {_: :body,
             c: case e.q['ui']
                when 'tabulator'
                  base = '//linkeddata.github.io/tabulator/'
                  [H.css(base+'tabbedtab'), H.js(base+'js/mashup/mashlib'),
                   {_: :script, c: "document.addEventListener('DOMContentLoaded', function(){tabulator.outline.GotoSubject(tabulator.kb.sym(window.location.href), true, undefined, true, undefined)})"},
                   {class: :TabulatorOutline, id: :DummyUUID, c: {_: :table, id: :outline}}]
                else
                  DefaultView[d,e]
                end}]}]}

  DefaultView = -> d,e {
    seen = {}

    # group resources on RDFtype
    groups = {}
    d.map{|u,r|
      (r||{}).types.map{|type|
        if v = ViewGroup[type]
          groups[v] ||= {}
          groups[v][u] = r
          seen[u] = true
        end}}

    e[:label] ||= {} # resource labels
    e[:sidebar] = [] # overview/control-pane

    path = e.R.justPath
    tabr = {_: :a, href: e.q.merge({'ui' => 'tabulator'}).qs, class: :tabr, c: {_: :img, src: '/css/misc/cube.svg'}, rel: :nofollow}

    # search-box
    e[:sidebar].push ViewA[SearchBox][{'uri' => '/search/'},e] if e[:container]

    [{_: :table, class: :pager, # direction pointers
      c: [{_: :tr,
           c: [{_: :td},{_: :td, c: ({_: :a, class: :dirname, href: path.dirname, c: '&#9650;'} if e[:container] && path != '/')},{_: :td}]}, # up
          {_: :tr,
           c: [{_: :td, c: e[:Links][:prev].do{|p|
                  p = CGI.escapeHTML p.to_s
                  {_: :a, rel: :prev, c: '&#9664;', title: p, href: p}}}, # left
               {_: :td, c: ({_: :a, class: :basename,
                             href: path, title: path, c: path.basename} if e[:container])}, # here
               {_: :td, c: e[:Links][:next].do{|n|
                  n = CGI.escapeHTML n.to_s
                  {_: :a, rel: :next, c: '&#9654;', title: n, href: n}}}]}, # right
          {_: :tr,
           c: [{_: :td},{_: :td, c: ({_: :a, class: :expand, href: e.q.merge({'full' => ''}).qs, c: "&#9660;", rel: :nofollow} if e[:summarized])},{_: :td}]}]}, # down
     groups.map{|view,graph|view[graph,e]}, # type-groups
     d.map{|u,r|                            # ungrouped
       if !seen[u]
         types = (r||{}).types
         type = types.find{|t|ViewA[t]}
         ViewA[type ? type : BasicResource][(r||{}),e]
       end},
     {class: :sidebar, c: e[:sidebar]},
     {_: :style,
      c: e[:label].map{|name,_| # label-colors
        c = randomColor
        "[name=\"#{name}\"] {color: #fff; background-color: #{c}; fill: #{c}; stroke: #{c}}\n"}},
     tabr, # upgrade to RDF-UI
     H.js('/js/ui',true) # keybinding-JS
    ]}

  ViewA[BasicResource] = -> r,e {
    {_: :table, class: :html, id: r.R.fragment || r.uri,
     c: r.map{|k,v|
       [{_: :tr, property: k,
        c: case k
           when 'uri'
             u = CGI.escapeHTML r.uri
             {_: :td, class: :uri, colspan: 2, c: {_: :a, class: :uri, href: u, c: u}}
           when Content
             {_: :td, class: :val, colspan: 2, c: v}
           when WikiText
             {_: :td, class: :val, colspan: 2, c: Render[WikiText][v]}
           when Atom+'enclosure'
             {_: :td, class: :val, colspan: 2, c: v.justArray.map{|v|
                resource = v.R
                if %w{png jpg gif}.member? resource.ext
                  {_: :img, src: resource.uri}
                else
                  resource
                end
              }}
           else
             icon = Icons[k]
             ["\n ",
              {_: :td,
               c: {_: :a, href: k, class: icon,
                   c: icon ? '' : (k.R.fragment||k.R.basename)}, class: :key}, "\n ",
              {_: :td, c: v.justArray.map{|v|
                 case v
                 when Hash
                   v.R
                 else
                   v
                 end
               }.intersperse(' '), class: :val}, "\n"
             ]
           end}, "\n"
       ]
     }}}

  ViewA[FOAF+'Person'] = -> r,e {
    {_: :a, class: :person, id: r.R.fragment, href: r.uri,
     upgrade: '//linkeddata.github.io/profile-editor/#/profile/view?webid='+URI.escape(r.uri),
     c: r[FOAF+'name'].justArray[0] || r.R.basename}}

  ViewGroup[BasicResource] = -> g,e {
    g.resources(e).reverse.map{|r|ViewA[BasicResource][r,e]}}

  ViewGroup[Container] = -> g,e {
    {class: :containers, c: g.map{|id,container|
       {class: :container,
        c: [{class: :label, c: {_: :a, href: id, c: id.R.basename}},
            {class: :contents, c: TabularView[{id => container},e,false,false]}]}}}}

  TabularView = ViewGroup[Stat+'File'] = ViewGroup[Resource] = ViewGroup[CSVns+'Row'] = -> g, e, show_head = true, show_id = true {

    sort = (e.q['sort']||'uri').expand                      # sort property
    direction = e.q.has_key?('reverse') ? :reverse : :id    # sort direction

    keys = g.values.select{|v|v.respond_to? :keys}.map(&:keys).flatten.uniq # base keys
    keys = keys - [Title, Label, Content, Image, Type, 'uri', Size]
    # put URI and typetag at beginning
    keys.unshift 'uri' if show_id
    keys.unshift Type
    keys.unshift Size
    rows = g.resources e         # sorted resources
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
                  ]}} if show_head),
         {_: :tbody, c: rows.map{|r|
            TableRow[r,e,sort,direction,keys]}}]}}

  TableRow = -> l,e,sort,direction,keys {
    this = l.R
    [{_: :tr, id: this.path, href: l.uri,
      c: ["\n",
          keys.map{|k|
            [{_: :td, property: k,
              c: case k
                 when 'uri'
                   {_: :a, href: (CGI.escapeHTML l.uri),
                    c: CGI.escapeHTML((l[Title]||l[Label]||this.basename).justArray[0])} if l.uri
                 when Type
                   l[Type].justArray.map{|t|
                     icon = Icons[t.uri]
                     {_: :a, href: CGI.escapeHTML(l.uri), c: icon ? '' : (t.R.fragment||t.R.basename), class: icon}}
                 when LDP+'contains'
                   l[k].do{|children|
                     children = children.justArray
                     if children[0].keys.size > 1 # tabular-view of contained children
                       childGraph = {}
                       children.map{|c|childGraph[c.uri] = c}
                       TabularView[childGraph,e,false]
                     else
                       children.map{|c|[c.R, ' ']}
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
                 end}, "\n"]}]},
     l[Content].do{|c|{_: :tr, c: {_: :td, class: :content, colspan: keys.size, c: c}}},
     l[Image].do{|c|
       {_: :tr,
        c: {_: :td, colspan: keys.size,
            c: c.justArray.map{|i|{_: :a, href: l.uri, c: {_: :img, src: i.uri, class: :tablePreview}}}.intersperse(' ')}}}]}

  def R.randomColor # fully saturated

    hsv2rgb = -> h,s,v {
      i = h.floor
      f = h - i
      p = v * (1 - s)
      q = v * (1 - (s * f))
      t = v * (1 - (s * (1 - f)))
      r,g,b=[[v,t,p],
             [q,v,p],
             [p,v,t],
             [p,q,v],
             [t,p,v],
             [v,p,q]][i].map{|q|q*255.0}}

    '#%02x%02x%02x' % hsv2rgb[rand*6,1,1]
  end

end
