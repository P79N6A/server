# -*- coding: utf-8 -*-
#watch __FILE__

def H _ # HTML as Ruby literal-values
  case _
  when Hash
    void = [:img, :input, :link, :meta].member? _[:_]
# [:area, :base, :br, :col, :embed, :hr, :img, :input, :keygen, :link, :meta, :param, :source, :track, :wbr] # void els

    '<' + (_[:_] || :div).to_s +                                     # name
      (_.keys - [:_,:c]).map{|a|                                     # attributes
      ' ' + a.to_s + '=' + "'" + _[a].to_s.chars.map{|c|
        {"'"=>'%27','>'=>'%3E','<'=>'%3C'}[c]||c}.join + "'"}.join + # values
      (void ? '/' : '') + '>' +                                      # void-el closer
      (_[:c] ? (H _[:c]) : '') +                                     # children
      (void ? '' : ('</'+(_[:_]||:div).to_s+'>'))                    # closer
  when Array
    _.map{|n|H n}.join
  else
    _.to_s if _
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
    env[name] = true
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
  def html; self.class end
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
                                   {_: :a,
                                    id: (u.fragment||u.uri),
                                    href: u.url,
                                    c: (self[R::Label] || self[R::Title] || u.abbr).justArray[0].to_s.hrefs,
                                    style: "background-color: #{R.cs}",
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
    yield uri+'#', Type, R[SIOC+'Content']
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

  def offset # human-readable
    (query_values.do{|q| q['offset'].do{|o| o.R.stripDoc}} ||
     self).hierPart.split('/').join(' ')
  end

  Render['text/html'] = -> d,e {
    u = d['#'] || {}
    titles = d.map{|u,r|r[Title] if r.class==Hash}.flatten.select{|t|t.class == String}

    H ['<!DOCTYPE html>', "\n",
       {_: :html,
         c: ["\n",
             {_: :head,
               c: ["\n",
                   {_: :meta, charset: 'utf-8'}, "\n",
                   {_: :title, c: titles.size==1 ? titles.head : e.uri}, "\n",
                   {_: :link, rel: :icon, href:'/css/misc/favicon.ico'}, "\n",
                   u[Next].do{|n|
                     [{_: :link, rel: :next, href: n.uri}, "\n"]},
                   u[Prev].do{|p|
                     [{_: :link, rel: :prev, href: p.uri}, "\n"]}]
             }, "\n",
             {_: :body,
               c: ["\n",
                   (View[e.q['view']] || DefaultView)[d,e]]}]},
       "\n"
      ]}

  DefaultView = -> d,e {
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

  Summarize = -> g,e { # data-reduction functions per RDF type
    groups = {}
    g.map{|u,r|
      r.types.map{|type|
        if v = Abstract[type]
          groups[v] ||= {}
          groups[v][u] = r
        end}}
    groups.map{|fn,gr|fn[g,gr,e]}}

  ViewA['default']= -> r,e {[r.html, H.once(e, 'default', H.css('/css/html',true))]}

  ViewGroup['default'] = -> g,e {g.map{|u,r|ViewA['default'][r,e]}}

  ViewA[SIOC+'Content'] = -> r,e {r[Content]}

  ViewA[LDP+'BasicContainer'] = -> r,e {
    re = r.R
    size = Stat + 'size'
    sort = e.q['sort'].do{|p|p.expand} || size
    sortType = [size].member?(sort) ? :to_i : :to_s
    [(H.once e, 'container', (H.css '/css/container')),
     {_: :p, class: 'basicC', style: "background-color: #{R.cs}",
      c: [{_: :a, class: :uri, c: r[Label] || re.abbr, href: re.uri}, ' ',
          r[LDP+'contains'].do{|c|
            [c.size > 1 &&
             [c.size > 2 && {_: :a, class: :sort, style: 'float: right', c: '↨', href: re.uri+'?sort=' + (sort==size ? 'dc:title' : 'stat:size')},
              '<br>'],
             c.sort_by{|i|(i.class == Hash && i[sort].justArray[0] || 0).send sortType}.reverse.map{|r|
               label = r.class == Hash && (r[Label] || r[Title])
               {_: :a, href: r.R.uri,
                class: :member,
                c: [r.class == Hash && r[size].do{|s|
                      s > 1 && {_: :b, c: [s,' ']}},
                    label ? [label.justArray[0].to_s.hrefs,"<br>"] : [r.R.abbr, " "]]}}]
          }]}]}

  ViewA[LDP+'Resource'] = -> u,e {
    [u[Prev].do{|p|{_: :a, rel: :prev, href: p.uri, c: ['&larr;', {class: :uri, c: p.R.offset}]}},
     u[Next].do{|n|{_: :a, rel: :next, href: n.uri, c: [{class: :uri, c: n.R.offset}, '&rarr;']}},
     ([(H.css '/css/page', true), (H.js '/js/pager', true), (H.once e,:mu,(H.js '/js/mu', true))] if u[Next]||u[Prev])]}

  %w{aif wav mpeg mp3 mp4}.map{|a|
    ViewA[MIMEtype+'audio/'+a] = ->r,e {
    [(H.once e, :audio, (H.js '/js/audio'), (H.css '/css/audio'),
     (H.once e, :mu, (H.js '/js/mu')),
      {id: :info, target: :_blank, _: :a},
      {_: e.q.has_key?('video') ? :video : :audio, id: :media, controls: true},
      {id: :jump, c: '&rarr;'}, {id: :rand, c: :rand, on: 1}),
     {_: :a, class: :track, href: r.uri, c: r.uri.split(/\//)[-1].sub(/\.(flac|mp3|wav)$/,'')}]}}

end
