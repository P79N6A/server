# -*- coding: utf-8 -*-
#watch __FILE__

def H x # rewrite Ruby to HTML
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
  when Array
    x.map{|n|H n}.join
  else
    x.html
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
    inline ? {_: :style, href: p, c: p.R.r} :
    {_: :link, href: p, rel: :stylesheet, type: R::MIME[:css]}
  end

end

class Array
  def cr; intersperse "\n" end
  def head; self[0] end
  def html; map(&:html).join ' ' end
  def h; join.h end
  def intersperse i
    inject([]){|a,b|a << b << i}[0..-2]
  end
  def tail; self[1..-1] end
  def justArray; self end
  def values; self end
end

class Object
  def html; self.class.to_s end
  def justArray; [self] end
end

class String
  def html
    self
  end
end

class Symbol
  def html; to_s end
end

class Bignum
  def html; to_s end
end

class Fixnum
  def html; to_s end
  def max i; i > self ? self : i end
  def min i; i < self ? self : i end
end

class Float
  def html; to_s end
  def max i; i > self ? self : i end
  def min i; i < self ? self : i end
end

class TrueClass
  def html; H({_: :input, type: :checkbox, title: :True, checked: :checked}) end
end

class FalseClass
  def html; H({_: :input, type: :checkbox, title: :False}) end
end

class NilClass
  def html; "" end
  def justArray; [] end
end

class Time
  def html; H({_: :time, datetime: iso8601, c: to_s}) end
end

class R

  def href name = nil
    H({_: :a, href: uri, c: name || fragment || basename})
  end
  alias_method :html, :href

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
      e[:title] = titles.head if titles.size==1 # there can be only one
    end
    paged = e[:Links][:next]||e[:Links][:prev]

    H ["<!DOCTYPE html>\n",
       {_: :html,
        c: [{_: :head,
             c: [{_: :meta, charset: 'utf-8'},
                 {_: :link, rel: :icon, href: '/.icon.png'},
                 e[:title].do{|t|{_: :title, c: t}},
                 e[:Links].do{|links|
                   links.map{|type,uri| {_: :link, rel: type, href: uri}}},
                 ([H.css('/css/page',true),
                   H.js('/js/pager',true)] if paged),
                 H.css('/css/icons',true),
                ]},
            {_: :body,
             c: [e.signedIn ?
                  {_: :a, class: :user, href: e.user.uri} :
                  {_: :a, class: :identify,href: e.scheme=='http' ? ('https://' + e.host + e['REQUEST_URI']) : '/whoami'},
                 e[:Links][:prev].do{|p| {_: :a, rel: :prev, href: p, c: ['&larr; ', p], title: '↩ previous page'}},
                 e[:Links][:next].do{|n| {_: :a, rel: :next, href: n, c: [n, ' →'], title: 'next page →'}},
                 ('<br>' if paged),
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
         ViewA[type ? type : Resource][(r||{}),e]
       end}]}

  ViewA[Resource] = -> r,e {
    uri = r.uri
    {class: :resource,
     c: [(if uri
          [({_: :a, href: uri, c: r[Date], class: :date} if r[Date]),
           ({_: :a, href: r.R.editLink(e), class: :edit, title: "edit #{uri}", c: R.pencil} if e.editable),
           {_: :a, href: uri, c: r[Title]||uri, class: :id},'<br>']
          end), r.html]}}

  ViewGroup[Resource] = -> g,e {
    [H.css('/css/html',true),
     g.resources(e).reverse.map{|r| # sort
       ViewA[Resource][r,e] }]}

end

class Hash
  def html
    if keys.size == 1 && has_key?('uri')
      r = self.R
      H({_: :a, href: uri, c: r.fragment || r.basename, class: :id})
    else
      id = if uri
             R[uri].fragment || uri
           else
             '#'
           end
      H({_: :table, class: :html, id: id,
         c: map{|k,v|
           {_: :tr, property: k,
            c: case k
               when R::Type
                 types = v.justArray
                 unless types.size==1 && types[0].uri==R::Resource
                   {_: :td, class: :val, colspan: 2,
                    c: ['a ', types.intersperse(', ').map(&:html),
                        types.map{|t|
                          R::Containers[t.uri].do{|c|
                            n = c.R.fragment
                            [' ',
                             {_: :a, href: id+'?new', class: :new,
                              c: ['+',n],
                              title: "post a #{n} to #{id.R.basename}"}]}}]}
                 end
               when R::Content
                 {_: :td, class: :val, colspan: 2, c: v}
               when R::WikiText
                 {_: :td, class: :val, colspan: 2, c: R::Render[R::WikiText][v]}
               else
                 [{_: :td, c: {_: :a, href: k, c: k.to_s.R.abbr}, class: :key},
                  {_: :td, c: v.html, class: :val}]
               end} unless k == 'uri'
         }})
    end
  end
end
