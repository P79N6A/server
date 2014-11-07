# -*- coding: utf-8 -*-
watch __FILE__

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
    e[:Graph] = d
    groups = {}
    seen = {}
    d.map{|u,r| # group resources on RDF class
      r.types.map{|type|
        if v = ViewGroup[type]
          groups[v] ||= {}
          groups[v][u] = r
          seen[u] = true
        end}} if e[:container]
    ls = View['ls']
    [groups.map{|view,graph|view[graph,e] if view!=ls}, # groups
     groups[ls].do{|g|ls[g,e]},
     d.map{|u,r|
       if !seen[u]
         type = r.types.find{|t|ViewA[t]}
         ViewA[type ? type : 'base'][r,e]
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

  View['base']= -> d,e {[d.values.map(&:html), H.once(e, 'base', H.css('/css/html',true))]}

  ViewA['base']= -> r,e {[r.html, H.once(e, 'base', H.css('/css/html',true))]}

  ViewA[SIOC+'Content'] = -> r,e {r[Content].do{|c|{_: :p, c: c}}}

  ViewA[LDP+'BasicContainer'] = -> r,e {
    re = r.R
    [(H.once e, 'container', (H.css '/css/container')),
     {class: 'basicC', style: "background-color: #{R.cs}",
      c: [{_: :a, c: e[:Graph][re.uri].do{|r|r[Label]} || re.abbr, href: r.uri},
          r[LDP+'contains'].do{|c|puts "Ccccccccunt",c
            ['<br>', c.map{|r| c = r.R
              label = e[:Graph][c.uri].do{|r|r[Label]} ||
                      (r.class == Hash && (r[Label]||r[Title]))
              {_: :a, href: c.uri, class: :member, c: label ? [label.justArray[0].to_s.hrefs,"<br>"] : [c.abbr, " "]}}]}]}]}

  ViewGroup[LDP+'BasicContainer'] = -> r,e {r.map{|u,r|ViewA[LDP+'BasicContainer'][r,e]}}

  ViewA[LDP+'Resource'] = -> u,e {
    [u[Prev].do{|p|{_: :a, rel: :prev, href: p.uri, c: ['&larr;', {class: :uri, c: p.R.offset}]}},
     u[Next].do{|n|{_: :a, rel: :next, href: n.uri, c: [{class: :uri, c: n.R.offset}, '&rarr;']}},
     ([(H.css '/css/page', true), (H.js '/js/pager', true), (H.once e,:mu,(H.js '/js/mu', true))] if u[Next]||u[Prev])]}

  View['audio'] = ->d,e {
    [(H.once e, :audio,
      (H.js '/js/audio'), (H.css '/css/audio'),
      (H.once e, :mu, (H.js '/js/mu')),
      {id: :info, target: :_blank, _: :a},
      {_: e.q.has_key?('video') ? :video : :audio, id: :media, controls: true},
      {id: :jump, c: '&rarr;'}, {id: :rand, c: :rand, on: 1}),
     d.map{|u,_|
       {_: :a, class: :track, href: u, c: u.split(/\//)[-1].sub(/\.(flac|mp3|wav)$/,'')}}]}

  %w{aif wav mpeg mp4}.map{|a|
    ViewGroup[MIMEtype+'audio/'+a]=View['audio']}

end
