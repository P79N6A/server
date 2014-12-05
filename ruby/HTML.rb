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
end

class Hash
  def html
    if keys.size == 1 && has_key?('uri')
      self.R.href
    else
      H [{_: :table, class: :html, c: map{|k,v|
            r = k.to_s.R
            [{_: :tr, property: k, c:
              [k == R::Content ? {_: :td, class: :val, colspan: 2, c: v} :
               ["\n",
                {_: :td,
                 c: (k == 'uri' ? {} : {_: :a, href: k, c: r.abbr}), class: :key},"\n",
                {_: :td,
                 c: k == 'uri' ? v.R.do{|u|
                                   {_: :a, id: (u.fragment||u.uri), href: u.uri,
                                    c: (self[R::Label] || self[R::Title] || u.abbr).justArray[0].to_s.noHTML,
                                   }} : v.html, class: :val}]]},
             "\n"] if k && v}},
         "\n"]
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
    titles = d.map{|u,r|r[Title] if r.class==Hash}.flatten.select{|t|t.class == String}
    H ["<!DOCTYPE html>\n",
       {_: :html,
         c: [{_: :head,
               c: [{_: :meta, charset: 'utf-8'},
                   {_: :title, c: titles.size==1 ? titles.head : e.uri},
                   {_: :link, rel: :icon, href: '/favicon.ico'},
                   u[Next].do{|n|
                     {_: :link, rel: :next, href: n.uri}},
                   u[Prev].do{|p|
                     {_: :link, rel: :prev, href: p.uri}}]},
             {_: :body, c: View[d,e]}]}]}

  View = -> d,e {
    groups = {}
    seen = {}
    d.map{|u,r| # group resources on RDF class
      r.types.map{|type|
        if v = ViewGroup[type]
          groups[v] ||= {}
          groups[v][u] = r
          seen[u] = true
        end}} if e[:container]
    [groups.map{|view,graph|view[graph,e]}, # groups
     d.map{|u,r|
       if !seen[u]
         type = r.types.find{|t|ViewA[t]}
         ViewA[type ? type : 'default'][r,e]
       end}]}

  %w{aif wav mpeg mp3 mp4}.map{|a|
    ViewA[MIMEtype+'audio/'+a] = ->r,e {
    [(H.once e, :audio, (H.js '/js/audio'), (H.css '/css/audio'),
     (H.once e, :mu, (H.js '/js/mu')),
      {id: :info, target: :_blank, _: :a},
      {_: e.q.has_key?('video') ? :video : :audio, id: :media, controls: true},
      {id: :jump, c: '&rarr;'}, {id: :rand, c: :rand, on: 1}),
     {_: :a, class: :track, href: r.uri, c: r.uri.split(/\//)[-1].sub(/\.(flac|mp3|wav)$/,'')}]}}

end
