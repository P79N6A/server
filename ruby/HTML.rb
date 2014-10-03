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

  def href name = nil
    H({_: :a, href: uri, c: name || abbr})
  end
  alias_method :html, :href

  def abbr
    uri.sub /(?<scheme>[a-z]+:\/\/)?(?<abbr>.*?)(?<frag>[^#\/]+)\/?$/,'<span class="abbr"><span class="scheme">\k<scheme></span>\k<abbr></span><span class="frag">\k<frag></span>'
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
    titles = d.map{|u,r|
      r[Title] if r.class==Hash}.flatten.select{|t|t.class == String }

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
                   (View[e.q['view']] || View['HTML'])[d,e],
                   u[Prev].do{|p|{_: :a, rel: :prev, href: p.uri, c: '&larr;', style: 'float: left'}},
                   u[Next].do{|n|{_: :a, rel: :next, href: n.uri, c: '&rarr;', style: 'float: right'}}]}]}]}

  View['HTML']=->d,e{ # default view
    e[:Graph] = d
    d.map{|u,r| # lookup RDF:type view
      type = r[Type].justArray.map(&:maybeURI).compact.map{|u|'http://'.R.join u}.find{|t|View[t.to_s]}
      View[type ? type.to_s : 'base'][{u => r},e]}}

  View['base']=->d,e{ # generic key/val view
    [d.values.map{|v|
       if v.uri.match(/(gif|jpe?g|png|tiff)$/i)
         ShowImage[v.uri]
       else
         v.html
       end
     }, H.once(e,'base',H.css('/css/html',true))]}

  View[LDP+'BasicContainer'] = -> i,e {
    [(H.once e, 'container', (H.css '/css/container')),
     i.map{|u,r|
       resource = r.R
       path = resource.justPath
       currentDir = path == e.R.justPath
       {class: 'dir ' + (currentDir ? 'thisdir' : ''), style: "background-color: #{R.cs}",
         c: [({_: :a, class: :up, c: '&uarr;', href: path.parentURI.descend} if currentDir && path != '/'),
             {_: :a, c: resource.abbr, href: resource.uri, rel: :nofollow},
             r[RDFs+'member'].do{|c|c.map{|c| c = c.R
                 {_: :a, href: c.uri, class: :member, c: e[:Graph][c.uri].do{|r|r[Label]} || c.abbr}}}]}}]}

  View[HTTP+'Response'] = -> d,e {
    d['#'].do{|u|
      [u[Prev].do{|p| # prev page
         {_: :a, rel: :prev, href: p.uri, c: ['&larr;', {class: :uri, c: p.R.offset}]}},
       u[Next].do{|n| # next page
         {_: :a, rel: :next, href: n.uri, c: [{class: :uri, c: n.R.offset}, '&rarr;']}},
       ([(H.css '/css/page', true), (H.js '/js/pager'), (H.once e,:mu,(H.js '/js/mu'))] if u[Next]||u[Prev])]}}

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
    View[MIMEtype+'audio/'+a]=View['audio']}

end
