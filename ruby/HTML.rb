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

  def H.once env, name, *h
    return if env[name]
    env[name] ||= true
    h
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

class Hash
  def html
    if keys.size == 1 && has_key?('uri')
      r = self.R
      H({_: :a, href: uri, c: r.fragment || r.basename, class: :id})
    else
      H({_: :table, class: :html, id: uri.do{|u|u.R.fragment||u.R.uri}||'#', c: map{|k,v|
           {_: :tr, property: k,
            c: case k
               when 'uri'
                 {_: :td, class: :uri, colspan: 2, c: {_: :a, href: v,
                      c: (self[R::Label] || self[R::Title] || v.R.abbr).justArray[0].to_s.noHTML}}
               when R::Content
                 {_: :td, class: :val, colspan: 2, c: v}
               else
                 [{_: :td, c: {_: :a, href: k, c: k.to_s.R.abbr}, class: :key},
                  {_: :td, c: v.html, class: :val}]
               end}}})
    end
  end
end

class Time
  def html; H({_: :time, datetime: iso8601, c: to_s}) end
end

class R

  def href name = nil
    H({_: :a, href: uri, c: name || fragment || basename})
  end
  alias_method :html, :href

  def abbr
    fragment || basename
  end

  def triplrContent
    yield uri+'#', Content, r
    yield uri+'#', Type, R[Content]
  end

  def triplrHref enc=nil
    yield uri, Content,
    H({_: :pre, style: 'white-space: pre-wrap',
        c: open(pathPOSIX).read.do{|r|
          enc ? r.force_encoding(enc).to_utf8 : r}.hrefs}) if f
  end

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
    if e.q.has_key? 'facets'
      Facets[d,e]
    elsif e.q.has_key? '?'
      Tabulator[d,e]
    else
      groups = {}
      seen = {}
      d.map{|u,r|
        r.types.map{|type|
          if v = ViewGroup[type]
            groups[v] ||= {}
            groups[v][u] = r
            seen[u] = true
          end}}
      [groups.map{|view,graph|view[graph,e]}, # groups
       d.map{|u,r|
         if !seen[u]
           type = r.types.find{|t|ViewA[t]}
           ViewA[type ? type : 'default'][r,e]
         end}]
    end}

end
