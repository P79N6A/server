# -*- coding: utf-8 -*-

def H x # Ruby to HTML
  case x
  when Hash
    void = [:img, :input, :link, :meta].member? x[:_]
    '<' + (x[:_] || 'div').to_s +                        # name
      (x.keys - [:_,:c]).map{|a|                         # attribute name
      ' ' + a.to_s + '=' + "'" + x[a].to_s.chars.map{|c| # attribute value
        {"'"=>'%27',
         '>'=>'%3E',
         '<'=>'%3C'}[c]||c}.join + "'"}.join +
      (void ? '/' : '') + '>' + (H x[:c]) +              # children or void
      (void ? '' : ('</'+(x[:_]||'div').to_s+'>'))       # closer
  when R
    H x.href
  when String
    x
  when Symbol
    x.to_s
  when Array
    x.map{|n|H n}.join
  when Float
    x.to_s
  when Integer
    x.to_s
  when NilClass
    ''
  else
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

  Render['text/html'] = -> graph,re,view=nil {
    e = re.env
    dir = re.path[-1] == '/'
    groups = {}
    empty = graph.empty?
    graph.map{|u,r|
      r.types.map{|type|
        if v = View[type]
          groups[v] ||= {}
          groups[v][u] = r
          graph.delete u
        end}}
    e[:label] ||= {}
    up = if re.q.has_key? 'full'
           re.q.reject{|k|k=='full'}.merge({'abbr' => ''}).qs
         elsif dir && re.path != '/'
           re.justPath.dirname + '?' + re.env['QUERY_STRING']
         end
    print = re.q.has_key? 'print'
    expanded = {_: :a, id: :down, href: re.q.reject{|k|k=='abbr'}.merge({'full' => ''}).qs, class: :expand, c: "&#9660;", rel: :nofollow} if re.env[:summarized]
    prevPage = e[:Links][:prev].do{|p|{_: :a, class: e[:prevEmpty] ? 'weak' : '',c: '&#9664;', rel: :prev, href: (CGI.escapeHTML p.to_s)}}
    nextPage = e[:Links][:next].do{|n|{_: :a, class: e[:nextEmpty] ? 'weak' : '',c: '&#9654;', rel: :next, href: (CGI.escapeHTML n.to_s)}}
    H ["<!DOCTYPE html>\n",
       {_: :html,
        c: [{_: :head,
             c: [{_: :meta, charset: 'utf-8'},
                 {_: :link, rel: :icon, href: '/.icon.png'},
                 e[:title].do{|t|{_: :title, c: CGI.escapeHTML(t)}},
                 e[:Links].do{|links|
                   links.map{|type,uri|
                     {_: :link, rel: type, href: CGI.escapeHTML(uri.to_s)}}},
                 H.css('/css/base',true)]},
            {_: :body,
             c: [([{_: :a, id: :up, href: up, c: '&#9650;'},'<br clear=all>'] if up && !print),
                 (prevPage && prevPage.merge({id: :prevpage})),
                 (nextPage && nextPage.merge({id: :nextpage})),
                 empty ? {_: :span, style: 'font-size:8em', c: 404} : '',
                 (TabularView[graph,re] if graph.keys.size > 0), groups.map{|view,graph|view[graph,re]},
                 {_: :style, c: e[:label].map{|name,_|
                    c = '#%06x' % (rand 16777216)
                    "[name=\"#{name}\"] {background-color: #{c}; border-color: #{c}; fill: #{c}; stroke: #{c}}\n"}}, H.js('/js/ui',true), '<br clear=all>',
                 (prevPage unless re.q.has_key? 'abbr'),
#                 (SearchBox[re] if dir),
                 (nextPage unless re.q.has_key? 'abbr'),
                 '<br clear=all>',
                 expanded,
                 {id: :statusbar}]}]}]}

  TabularView = -> g, e, show_head = true, show_id = true {
    sort = (e.q['sort']||'dc:date').expand
    direction = e.q.has_key?('ascending') ? :id : :reverse
    g[e.uri].do{|t|t.delete Size;t.delete Date}
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
    isImg = types.member? Image
    thisDir = this.uri[-1]=='/' && e.path == this.path
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
                     href = CGI.escapeHTML(l.uri||'')
                     title = l[Title].justArray[0]
                     name = CGI.escapeHTML (this.fragment || this.basename)
                     [({_: :a, class: :title, href: href, c: CGI.escapeHTML(title)} if title), ' ', # title
                      {_: title ? :span : :a, class: :uri, href: href, c: name}, # URI
                      (title ? '<br>' : ' '),
                      l[Content].justArray.map{|c| monospace ? {_: :pre, c: c} : c },
                      (['<br>',{_: :a, href: this.uri,
                        c: {_: :img, class: :thumb,
                            src: if (this.host != e.host) || this.ext.downcase == 'gif'
                             this.uri
                           else
                             '/thumbnail' + this.path
                            end}}] if isImg),
                      l[DC+'link'].do{|links|
                        big = links.size > 8
                        links[0..32].map{|link|
                          id = link.R.uri
                          [{_: :a, class: :link, href: id, c: (CGI.escapeHTML id)}.update(big ? {} : {id: e.selector}),(big ? ' ' : '<br>')]}},
                     ]
                   end
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
                       children.map{|c|[(CGI.escapeHTML c.R.basename[0..15]), ' ']}
                     end}
                 when Label
                   l[k].justArray.map{|v|
                     label = (v.respond_to?(:uri) ? (v.R.fragment || v.R.basename) : v).to_s
                     lbl = label.downcase.gsub(/[^a-zA-Z0-9_]/,'')
                     e.env[:label][lbl] = true
                     [{_: :a, href: this.uri, name: lbl, c: label},' ']}
                 when Schema+'logo'
                   l[k].justArray.map{|logo|
                     if logo.respond_to?(:uri)
                       {_: :a, href: l[DC+'link'].justArray[0].do{|l|l.uri}||'#',
                        c: {_: :img, class: :logo, src: logo.uri}}
                     end
                   }
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

end
