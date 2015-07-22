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
    if !view
      view = if e.q.has_key? 'data'
               Tabulator
             else
               View
             end
    end
    if !e[:title]
      titles = d.map{|u,r|r[Title] if r.class==Hash}.flatten.select{|t|t.class == String}
      e[:title] = titles.size==1 ? titles.head : e.uri
    end
    e[:color] = R.randomColor
    nxt = e[:Links][:next].do{|n|CGI.escapeHTML n}
    prev = e[:Links][:prev].do{|p|CGI.escapeHTML p}
    paged = nxt||prev
    br = '<br clear="all"/>'

    H ["<!DOCTYPE html>\n",
       {_: :html,
        c: [{_: :head,
             c: [{_: :meta, charset: 'utf-8'},
                 {_: :link, rel: :icon, href: '/.icon.png'},
                 e[:title].do{|t|{_: :title, c: CGI.escapeHTML(t)}},
                 e[:Links].do{|links|
                   links.map{|type,uri|
                     {_: :link, rel: type, href: CGI.escapeHTML(uri.to_s)}}},
                 ([H.css('/css/page',true), H.js('/js/pager',true)] if paged),
                 H.js('/js/kbd',true), H.css('/css/base',true)]},
            {_: :body,
             c: [e.signedIn ?
                  {_: :a, class: :user, href: e.user.uri} :
                  {_: :a, class: :identify,href: e.scheme=='http' ? ('https://' + e.host + e['REQUEST_URI']) : '/whoami'},
                 ({_: :a, rel: :prev, href: prev, c: '←', title: 'previous page'} if prev),
                 ({_: :a, rel: :next, href: nxt, c: '→', title: 'next page'} if nxt),
                 (br if paged),
                 view[d,e],
                 ([br,{_: :a, rel: :next, href: nxt, c: '→'}] if nxt),
                ]}]}]}

  View = -> d,e { # default view - group by type, try type-render, fallback to generic
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
    uri = if r.uri
            r.uri.split(e.uri)[-1]
          else
            rand.to_s.h
          end
    resource = r.R
    {_: :table, class: :html, id: uri,
     c: r.map{|k,v|
       [{_: :tr, property: k,
        c: case k
           when 'uri'
             {_: :td, colspan: 2, c: {_: :a, class: :uri, href: uri, c: uri}}
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
             rdfType = Type == k
             ["\n ",
              {_: :td,
               c: {_: :a, href: rdfType ? (r.R.docroot.uri+'?data') : k, class: icon,
                   c: if rdfType
                    {_: :img, src: '/css/misc/cube.svg'}
                  else
                    icon ? '' : (k.R.fragment||k.R.basename)
                   end}, class: :key}, "\n ",
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

  ViewGroup[BasicResource] = -> g,e {
    g.resources(e).reverse.map{|r|ViewA[BasicResource][r,e]}}

  Icons = {
    'uri' => :id,
    Container => :dir,
    Date => :date,
    Label => :tag,
    Title => :title,
    Directory => :warp,
    FOAF+'Person' => :person,
    Image => :img,
    LDP+'contains' => :container,
    Size => :size,
    Mtime => :time,
    Resource => :graph,
    Forum => :comments,
    WikiArticle => :pencil,
    Atom+'self' => :graph,
    Atom+'alternate' => :file,
    Atom+'edit' => :pencil,
    Atom+'replies' => :comments,
    RSS+'link' => :link,
    RSS+'guid' => :id,
    RSS+'comments' => :comments,
    SIOC+'Usergroup' => :group,
    SIOC+'wikiText' => :pencil,
    SIOC+'has_creator' => :user,
    SIOC+'has_container' => :dir,
    SIOC+'has_discussion' => :comments,
    SIOC+'has_parent' => :reply,
    SIOC+'reply_to' => :reply,
    Stat+'File' => :file,
    '#editable' => :scissors,
  }

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
