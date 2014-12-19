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

  def nokogiri;  Nokogiri::HTML.parse (open uri).read end

  StripHTML = -> body, loseTags=%w{iframe script style}, keepAttr=%w{alt href rel src title type} {
    html = Nokogiri::HTML.fragment body
    loseTags.map{|tag| html.css(tag).remove } if loseTags
    html.traverse{|e|e.attribute_nodes.map{|a|a.unlink unless keepAttr.member? a.name}} if keepAttr
    html.to_xhtml}

  Render['text/html'] = -> d,e {
    u = d[''] || {}
    e[:title] = d.map{|u,r|r[Title] if r.class==Hash}.flatten.select{|t|t.class == String}
    H ["<!DOCTYPE html>\n",
       {_: :html,
         c: [{_: :head,
               c: [{_: :meta, charset: 'utf-8'},
                   {_: :title, c: e[:title].size==1 ? e[:title].head : e.uri},
                   {_: :link, rel: :icon, href: '/favicon.ico'},
                   u[Next].do{|n|
                     {_: :link, rel: :next, href: n.uri}},
                   u[Prev].do{|p|
                     {_: :link, rel: :prev, href: p.uri}}]},
             {_: :body, c: View[d,e]}]}]}

  View = -> d,e {
    if e.q.has_key? '?'
      Tabulator[d,e]
    else
      groups = {}
      seen = {}
      d.map{|u,r| # group resources on RDF type
        r.types.map{|type|
          if v = ViewGroup[type]
            groups[v] ||= {}
            groups[v][u] = r
            seen[u] = true
          end}}

      [groups.map{|view,graph|view[graph,e]}, # type-groups
       d.map{|u,r|                            # singletons
         if !seen[u]
           types = r.types
           type = types.find{|t|ViewA[t]}
           if types.empty?
             puts "untyped resource <#{r.uri}>"
           else
             puts "view undefined #{types.join ' '}"
           end
           ViewA[type ? type : Resource][r,e]
         end}]
    end}

end
