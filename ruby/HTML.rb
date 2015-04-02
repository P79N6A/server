# -*- coding: utf-8 -*-
#watch __FILE__

def H x # rewrite Ruby values to HTML
  case x
  when String
    x
  when Array
    x.map{|n|H n}.join
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
  when TrueClass
    '<input type="checkbox" title="True" checked="checked"/>'
  when FalseClass
    '<input type="checkbox" title="True"/>'
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
    puts ["undefined HTML format for",x.class].join ' '
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
    html = Nokogiri::HTML.fragment body
    loseTags.map{|tag| html.css(tag).remove } if loseTags
    html.traverse{|e|e.attribute_nodes.map{|a|a.unlink unless keepAttr.member? a.name}} if keepAttr
    html.to_xhtml}

  Render['text/html'] = -> d,e,view=View {
    if !e[:title]
      titles = d.map{|u,r|r[Title] if r.class==Hash}.flatten.select{|t|t.class == String}
      e[:title] = titles.size==1 ? titles.head : e.uri
    end
     nxt = e[:Links][:next].do{|n|CGI.escapeHTML n}
    prev = e[:Links][:prev].do{|p|CGI.escapeHTML p}
    paged = nxt||prev

    H ["<!DOCTYPE html>\n",
       {_: :html,
        c: [{_: :head,
             c: [{_: :meta, charset: 'utf-8'},
                 {_: :link, rel: :icon, href: '/.icon.png'},
                 e[:title].do{|t|{_: :title, c: CGI.escapeHTML(t)}},
                 e[:Links].do{|links|
                   links.map{|type,uri| {_: :link, rel: type, href: CGI.escapeHTML(uri.to_s)}}},
                 ([H.css('/css/page',true),
                   H.js('/js/pager',true)] if paged),
                 H.css('/css/icons',true),
                ]},
            {_: :body,
             c: [e.signedIn ?
                  {_: :a, class: :user, href: e.user.uri} :
                  {_: :a, class: :identify,href: e.scheme=='http' ? ('https://' + e.host + e['REQUEST_URI']) : '/whoami'},
                 {_: :a, href: '?rdf', rel: :nofollow, c: {_: :img, src: '/css/misc/cube.svg', style: 'float:right;width:2.3em'}},
                 ({_: :a, rel: :prev, href: prev, c: ['&larr; ', prev], title: '↩ previous page'} if prev),
                 ({_: :a, rel: :next, href: nxt, c: [nxt, ' →'], title: 'next page →'} if nxt),
                 ('<br clear="all"/>' if paged),
                 view[d,e]]}]}]}

  View = -> d,e { # default view - group by type, try type-renderers, fallback to generic
    groups = {}
    seen = {}
    d.map{|u,r| # group on RDF type
      (r||{}).types.map{|type|
        if v = ViewGroup[type]
          groups[v] ||= {}
          groups[v][u] = r
          seen[u] = true
        end}}

    [groups.map{|view,graph|view[graph,e]}, # show type-groups
     d.map{|u,r|                            # show singletons
       if !seen[u]
         types = (r||{}).types
         type = types.find{|t|ViewA[t]}
         ViewA[type ? type : BasicResource][(r||{}),e]
       end}]}

  ViewA[BasicResource] = -> r,e {
    uri = r.uri
    {class: :resource,
     c: [(if uri
          [({_: :a, href: uri, c: r[Date], class: :date} if r[Date]),
           ({_: :a, href: r.R.editLink(e), class: :edit, title: "edit #{uri}", c: R.pencil} if e.editable),
           {_: :a, href: uri, c: r[Title]||uri, class: :id},'<br>']
          end),
         {_: :table, class: :html, id: id,
          c: r.map{|k,v|
            {_: :tr, property: k,
             c: case k
                when Type
                  types = v.justArray
                  {_: :td, class: :val, colspan: 2,
                   c: ['a ', types.intersperse(', ').map{|t|t.R.href}]}
                when Content
                  {_: :td, class: :val, colspan: 2, c: v}
                when WikiText
                  {_: :td, class: :val, colspan: 2, c: Render[WikiText][v]}
                else
                  [{_: :td, c: {_: :a, href: k, c: k.to_s.R.abbr}, class: :key},
                   {_: :td, c: v.justArray.map{|v|
                      case v
                      when R
                        v
                      when Hash
                        v.R
                      else
                        v
                      end
                    }, class: :val}]
                end} unless k == 'uri'}}]}}

  ViewGroup[BasicResource] = -> g,e {
    [H.css('/css/html',true),
     g.resources(e).reverse.map{|r| # sort
       ViewA[BasicResource][r,e] }]}

end
