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

  require 'nokogiri'
  def nokogiri
    Nokogiri::HTML.parse (open uri).read
  end

  StripHTML = -> body, loseTags=%w{iframe script style}, keepAttr=%w{alt href rel src title type} {
    html = Nokogiri::HTML.fragment body
    loseTags.map{|tag| html.css(tag).remove} if loseTags
    html.traverse{|e|
      e.attribute_nodes.map{|a|
        a.unlink unless keepAttr.member? a.name}} if keepAttr
    html.to_xhtml}

  Render['text/html'] = -> d,re,view=nil {
    env = re && re.env || {} 
    H ["<!DOCTYPE html>\n",
       {_: :html,
        c: [{_: :head,
             c: [{_: :meta, charset: 'utf-8'},
                 {_: :link, rel: :icon, href: '/.icon.png'},
                 env[:title].do{|t|{_: :title, c: CGI.escapeHTML(t)}},
                 env[:Links].do{|links|
                   links.map{|type,uri|
                     {_: :link, rel: type, href: CGI.escapeHTML(uri.to_s)}}},
                 H.css('/css/base',true)]},
            {_: :body, c: DefaultView[d,re]}]}]}

  DefaultView = -> d,re {
    e = re && re.env || {}
    seen = {}
    groups = {}
    d.map{|u,r|
      (r||{}).types.map{|type|
        if v = ViewGroup[type]
          groups[v] ||= {} ## init group
          groups[v][u] = r ## add resource to group
          seen[u] = true # mark selection
        end}}

    e[:label] ||= {}
    path = e.R.justPath
    parent = {_: :a, class: :dirname, id: :up, href: path.dirname, c: '&#9650;'} unless path == '/'
    prevPage = e[:Links][:prev].do{|p|
      p = CGI.escapeHTML p.to_s
      {_: :a, id: :prevpage, class: e[:prevEmpty] ? 'weak' : '',
       c: '&#9664;', title: p, rel: :prev, href: p}}
    nextPage = e[:Links][:next].do{|n|
      n = CGI.escapeHTML n.to_s
      {_: :a, id: :nextpage, class: e[:nextEmpty] ? 'weak' : '',
       c: '&#9654;', title: n, rel: :next, href: n}}
    
    [{id: :statusbar},    
     prevPage, parent,
     (ViewA[SearchBox][{'uri' => '/search/'},re] if e[:search]),
     nextPage,
     groups.map{|view,graph|view[graph,re]}, # resource groups
     d.map{|u,r|                           # singleton resources
       if !seen[u]
         types = (r||{}).types
         type = types.find{|t|ViewA[t]}
         ViewA[type ? type : BasicResource][(r||{}),re]
       end},
     {_: :style, c: e[:label].map{|name,_| # colorize labels
        c = randomColor
        "[name=\"#{name}\"] {background-color: #{c}; border-color: #{c}; fill: #{c}; stroke: #{c}}\n"}},
     H.js('/js/ui',true),
     '<br clear=all>',
     prevPage,
     ({_: :a, id: :enter, href: re.q.merge({'full' => ''}).qs, class: :expand, c: "&#9660;", rel: :nofollow} if re.env[:summarized]),
     nextPage,
    ]}

  ViewA[BasicResource] = -> r,e {
    {_: :table, id: e.selector, href: r.uri,
     c: r.map{|k,v|
       [{_: :tr, property: k,
        c: case k
           when 'uri'
             u = CGI.escapeHTML r.uri
             {_: :td, class: :uri, colspan: 2, c: {_: :a, style: 'font-size:2em', href: u, c: u.R.basename}}
           when Content
             {_: :td, class: :val, colspan: 2, c: v}
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
           end}, "\n"]}}}

  
  ViewA[FOAF+'Person'] = ViewA[SIOC+'Usergroup'] = -> r,e {
    ['<br>',
      {_: :a, class: :person,
      id: r.R.fragment,
      href: 'https://linkeddata.github.io/profile-editor/#/profile/view?webid='+URI.escape(r.uri),
      c: r[FOAF+'name'].justArray[0] || r.R.basename},
     '<br>',
     {_: :a, id: e.selector, class: :nextpage, c: '&#9654;', href: r.R.dirname+'?set=page'}
    ] if r.uri.match(/^http/)}

  
  ViewGroup[BasicResource] = -> g,e {
    g.resources(e).reverse.map{|r|ViewA[BasicResource][r,e]}}

  
  ViewA[Container] = -> container,e {TabularView[{container.uri => container},e,false,false]}
  
  TabularView = ViewGroup[CSVns+'Row'] = -> g, e, show_head = true, show_id = true {

    sort = (e.q['sort']||'dc:date').expand
    direction = e.q.has_key?('ascending') ? :id : :reverse

    keys = g.values.select{|v|v.respond_to? :keys}.map(&:keys).flatten.uniq
    keys = [Label, Type, *(keys - [Mtime,Label,Type,Title,Image,Content,DC+'link'])]

    {_: :table,
     c: [
       {_: :tbody, c: (g.resources e).map{|r|
          TableRow[r,e,sort,direction,keys]}},
       {_: :tr,
         c: [keys.map{|k|

               q = e.q.merge({'sort' => k.shorten})
               if direction == :id
                 q.delete 'ascending'
               else
                 q['ascending'] = ''
               end

               href = CGI.escapeHTML q.qs

               [{_: :th, id: e.selector, href: href,
                 property: k,
                 class: k == sort ? 'selected' : '',
                 c: {_: :a,
                     rel: :nofollow,
                     href: href,
                     class: Icons[k]||'',
                     c: k == Type ? '' : {_: :span, class: :label, c: k.R.fragment||k.R.basename}}}, "\n"]}]}]}}

  TableRow = -> l,e,sort,direction,keys {
    this = l.R
    types = l.types
    monospace = types.member? SIOC+'InstantMessage'
    thisDir = this.uri[-1]=='/' && e.R.uri == this.uri
    [{_: :tr, class: :selectable,
      href: this.uri,
      id: thisDir ? 'this' : e.selector,
       c: ["\n",
          keys.map{|k|
            [{_: :td, property: k, class: sort==k ? 'selected' : '',
              c: case k
                 when 'uri'
                   if thisDir
                     {_: :span, style: 'font-size:2em;font-weight:bold', c: this.basename}
                   else
                     href = CGI.escapeHTML l.uri
                     title = l[Title].justArray[0]
                     name = CGI.escapeHTML (this.fragment || this.basename)
                     [(title ? {_: :a,    class: :title, href: href, c: CGI.escapeHTML(title)}    : ''),' ', # explicit Title
                      (title ? {_: :span, class: :name, c: {_: :font, color: '#777777', c: name}} : (l[Content] ? '' : {_: :a, class: :uri, href: href, c: name})), # URI detail
                      l[Content].justArray.map{|c| monospace ? {_: :span, class: :monospace, c: c} : c },
                      l[DC+'link'].do{|links|
                        big = links.size > 8
                        links[0..32].map{|link|
                          id = link.R.uri
                          [(big ? ' ' : '<br>'),{_: :a, class: :link, href: id, c: (CGI.escapeHTML id)}.update(big ? {} : {id: e.selector})]}},
                     ]
                   end
                 when Type
                   thisDir ? '' : l[Type].justArray.map{|t|
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
                       children.map{|c|[(CGI.escapeHTML c.R.basename[0..15]), ' ']}
                     end}
                 when Label
                   l[k].justArray.map{|v|
                     label = (v.respond_to?(:uri) ? (v.R.fragment || v.R.basename) : v).to_s
                     lbl = label.downcase.gsub(/[^a-zA-Z0-9_]/,'')
                     e.env[:label][lbl] = true
                     [{_: :a, href: this.uri, name: lbl, c: label},' ']}
                 when SIOC+'has_container'
                 when SIOC+'has_creator'
                   l[k].justArray.map{|v|
                     name = v.R.fragment||''
                     label = name.downcase.gsub(/[^a-zA-Z0-9_]/,'')
                     e.env[:label][label] = true
                     [{_: :a, href: this.uri, name: label, c: name},' ']}
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
     l[Image].do{|c|
       {_: :tr,
        c: [{_: :td},
            {_: :td, colspan: (keys.size - 1), c: c.justArray.map{|i|
               {_: :a, href: l.uri, c: {_: :img, src: i.uri, class: :preview}}}.intersperse(' ')}
           ]}}]}

  ## TODO, make this view opt-out..
  ViewGroup[Container] = ViewGroup[Resource] = ViewGroup[Stat+'File'] = ViewGroup[Sound] = ViewGroup[SIOC+'Thread'] = ViewGroup[SIOC+'SourceCode'] = ViewGroup[SIOC+'TextFile'] = ViewGroup[SIOC+'InstantMessage'] =  ViewGroup[SIOC+'Post'] = ViewGroup[SIOC+'MicroblogPost'] = ViewGroup[SIOC+'Tweet'] = ViewGroup[SIOC+'Discussion'] = TabularView

  ViewA[Image] = ->img,e{
    image = img.R
    {_: :a, href: image.uri,
     c: {_: :img, class: :thumb,
         src: if (image.host != e.host) || image.ext.downcase == 'gif'
                image.uri
              else
                '/thumbnail' + image.path
              end}}}

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
