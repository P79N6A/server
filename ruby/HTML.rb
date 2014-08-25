# -*- coding: utf-8 -*-
#watch __FILE__

def H _
  case _
  when Hash
#    void = [:area, :base, :br, :col, :embed, :hr, :img, :input, :keygen, :link, :meta, :param, :source, :track, :wbr].member? _[:_]
    void = [:img, :input, :link].member? _[:_]
    '<' + (_[:_] || :div).to_s + # name
      (_.keys - [:_,:c]).map{|a| # attributes
      ' ' + a.to_s + '=' + "'" + _[a].to_s.chars.map{|c|{"'"=>'%27','>'=>'%3E','<'=>'%3C'}[c]||c}.join + "'"}.join + # values
      (void ? '/' : '') + '>' + # opener
      (_[:c] ? (H _[:c]) : '') + # child nodes
      (void ? '' : ('</'+(_[:_]||:div).to_s+'>')) # closer
  when Array
    _.map{|n|H n}.join
  else
    _.to_s if _
  end
end

class H

  def H.[] h; H h end

  def H.js a,inline=false
    p = a + '.js'
    inline ? {_: :script, c: p.R.r} :
    {_: :script, type: "text/javascript", src: p}
  end

  def H.css a,inline=false
    p = a + '.css'
    inline ? {_: :style, href: p, c: p.R.r} :
    {_: :link, href: p, rel: :stylesheet, type: R::MIME[:css]}
  end

  def H.once e,n,*h
    return if e[n]
    e[n]=true
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
            [{_: :tr, property: k, c:
              [k == R::Content ? {_: :td, class: :val, colspan: 2, c: v} :
               ["\n",
                {_: :td, c: (k == 'uri' ? {} : {_: :a, name: k, href: k, c: R[k.to_s].abbr}), class: :key},"\n",
                {_: :td, c: k == 'uri' ? v.R.do{|u| {_: :a, id: u, href: u.url, c: v}} : v.html, class: :val}]]},
             "\n"]}},
         "\n"]
    end
  end
end

class R

  LazyView = %w{tabulate warp}

  def href name = nil
    H({_: :a, href: uri, c: name || abbr})
  end
  alias_method :html, :href

  def abbr
    uri.sub /(?<scheme>[a-z]+:\/\/)?(?<abbr>.*?)(?<frag>[^#\/]+)\/?$/,'<span class="abbr"><span class="scheme">\k<scheme></span>\k<abbr></span><span class="frag">\k<frag></span>'
  end

  View['HTML']=->d,e{ # default render - dispatch on RDF-type
    e[:Graph] = d
    d.map{|u,r|
      type = r[Type].justArray.map(&:maybeURI).compact.map{|u|'http://'.R.join u}.find{|t|View[t.to_s]}
      View[type ? type.to_s : 'base'][{u => r},e]}}

  View['base']=->d,e{
    [d.values.map{|v|
       if v.uri.match(/(gif|jpe?g|png|tiff)$/i)
         ShowImage[v.uri]
       else
         v.html
       end
     }, H.once(e,'base',H.css('/css/html',true))]}

  View['title'] = -> g,e {g.map{|u,r| {_: :a, href: u, c: r[Title] || u}}}

  View[LDP+'BasicContainer'] = -> i,e {
    [(H.once e, 'container', (H.css '/css/container')),
     i.map{|u,r| resource = r.R
       {class: :dir, style: "background-color: #{R.cs}",
         c: [resource.href,
             r[RDFs+'member'].do{|c|c.map{|c|c = c.R
                 label = e[:Graph][c.uri].do{|r|r[Label]} # resource label if exists
                 [(c.href label),' ']}}]}}]} # link

  def triplrHref enc=nil
    yield uri, Content, H({_: :pre, style: 'white-space: pre-wrap',
                            c: open(d).read.do{|r| enc ? r.force_encoding(enc).to_utf8 : r}.hrefs}) if f
  end

  def nokogiri;  Nokogiri::HTML.parse (open uri).read end

  def triplrHTML
    yield uri, Type, R[HTML]
    yield uri, Content, r
  end

  # HTML fragment, RDF type <http://www.w3.org/1999/02/22-rdf-syntax-ns#HTML>
  View[HTML] = -> g,e {g.map{|u,r|r[Content]}} # <http://www.w3.org/TR/rdf11-concepts/#section-html>

  StripHTML = -> body, loseTags=%w{iframe script style}, keepAttr=%w{alt href rel src title type} {
    html = Nokogiri::HTML.fragment body
    loseTags.map{|tag| html.css(tag).remove } if loseTags
    html.traverse{|e|e.attribute_nodes.map{|a|a.unlink unless keepAttr.member? a.name}} if keepAttr
    html.to_xhtml}

  def offset # human-readable
    (query_values.do{|q| q['offset'].do{|o| o.R.stripDoc}} ||
     self).hierPart.split('/').join(' ')
  end

  Render['text/html'] = -> d,e { u = d['#']||{}
    titles = d.map{|u,r|r[Title] if r.class==Hash}.flatten.select{|t|t.class==String}
    H ['<!DOCTYPE html>',{_: :html,
         c: [{_: :head, c: ['<meta charset="utf-8" />',
                  ({_: :title, c: titles.head} if titles.size==1),
                   {_: :link, rel: :icon, href:'/css/misc/favicon.ico'},
     u[Next].do{|n|{_: :link, rel: :next, href: n.uri}},
     u[Prev].do{|p|{_: :link, rel: :prev, href: p.uri}}]},
             {_: :body, c: (View[e.q['view']] || View['HTML'])[d,e]}]}]}

  View['ls'] = ->d=nil,e=nil {
    keys = ['uri',Stat+'size',Type,Date,Title]
    [{_: :table,
       c: [{_: :tr, c: keys.map{|k|{_: :th, c: k.R.abbr}}},
           d.values.map{|e|
             {_: :tr, c: keys.map{|k| {_: :td, c: k=='uri' ? e.R.html : e[k].html}}}}]},
     H.css('/css/table')]}

  View[Stat+'File'] = -> i,e {
    [(H.once e, 'container', (H.css '/css/container')),
     i.map{|u,r|
       r[Stat+'size'].do{|s|
         {class: :File, title: "#{u}  #{s[0]} bytes",
           c: ["\n", {_: :a, class: :file, href: u, c: '☁'},
               "\n", {_: :a, class: :view, href: u.R.stripDoc.a('.html'), c: u.R.abbr},
               "\n", r[Content], "\n"]}}}]}

  View[Stat+'Link'] = -> i,e {
    i.map{|u,r| r[Stat+'target'].do{|t|
        {_: :a, href: t[0].uri, c: t[0].uri}}}}

  View['audio'] = ->d,e {
    [(H.once e, :audio,
      (H.js '/js/audio'), (H.css '/css/audio'),
      (H.once e, :mu, (H.js '/js/mu')),
      {id: :info, target: :_blank, _: :a},
      {_: e.q.has_key?('video') ? :video : :audio, id: :media, controls: true},
      {id: :jump, c: '&rarr;'}, {id: :rand, c: :rand, on: 1}),
     d.map{|u,_|
       {_: :a, class: :track, href: URI.escape(u), c: u.split(/\//)[-1].sub(/\.(flac|mp3|wav)$/,'')}}]}

  %w{aif wav mpeg mp4}.map{|a|
    View[MIMEtype+'audio/'+a]=View['audio']}

end
