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
    {_: :a,
     #selectable: true, id: rand.to_s.h[0..5],
     href: uri, c: name || fragment || basename}
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

    if !e[:title]
      titles = d.map{|u,r|r[Title] if r.class==Hash}.flatten.select{|t|t.class == String}
      e[:title] = titles.size==1 ? titles.head : e.uri
    end

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
            {_: :body, c: View[d,e]}]}]}

  View = -> d,e { # default view
    groups = {}
    seen = {}
    d.map{|u,r| # group by RDF type
      (r||{}).types.map{|type|
        if v = ViewGroup[type]
          groups[v] ||= {}
          groups[v][u] = r
          seen[u] = true
        end}}

    e[:label] ||= {} # labels
    e[:sidebar] = [] # control pane

    if e[:container]
      path = e.R.justPath
      up = path.dirname
      e[:sidebar].push({_: :span, class: :path,
                        c: [{_: :a, class: :dirname, href: up, c: '&uarr;'},
                            {_: :a, class: :basename, href: e.q.merge({'table'=>'table'}).qs, title: path, c: path.basename}]})
    end

    e[:sidebar].push({_: :span, class: :paginate,
                      c: [e[:Links][:prev].do{|p|
                            p = CGI.escapeHTML p.to_s
                            {_: :a, rel: :prev, c: '&#9664;', title: p, href: p}},
                          e[:Links][:next].do{|n|
                            n = CGI.escapeHTML n.to_s
                            {_: :a, rel: :next, c: '&#9654;', title: n, href: n}},
                         ]}) if e[:Links][:prev] || e[:Links][:next]

    [groups.map{|view,graph|view[graph,e]}, # type-groups
     d.map{|u,r|                            # singletons
       if !seen[u]
         types = (r||{}).types
         type = types.find{|t|ViewA[t]}
         ViewA[type ? type : BasicResource][(r||{}),e]
       end},
     {class: :sidebar, c: e[:sidebar]},
     {_: :style, c: e[:label].map{|name,_|
        c = randomColor
        "[name=\"#{name}\"] {color: #000; background-color: #{c}; fill: #{c}; stroke: #{c}}\n"}},
     H.js('/js/kbd',true)]}

  ViewA[BasicResource] = -> r,e {
    fragment = r.R.fragment || r.uri
    {_: :table, class: :html, id: fragment,
     c: r.map{|k,v|
       [{_: :tr, property: k, id: [r.uri,k].h, selectable: :true,
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
