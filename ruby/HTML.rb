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
    inline ? {_: :style, c: p.R.r} :
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
  def html v=nil; map{|e|e.html v}.join ' ' end
  def h; join.h end
  def intersperse i
    inject([]){|a,b|a << b << i}[0..-2]
  end
  def tail; self[1..-1] end
  def justArray; self end
end

class Object
  def html *a; self.class end
end

class String
  def br
    gsub(/\n/,"<br>\n")
  end
  def href name=nil
    '<a href="'+self+'">' + (name||abbrURI) + '</a>'
  end
  def abbrURI
    sub /(?<scheme>[a-z]+:\/\/)?(?<abbr>.*?)(?<frag>[^#\/]+)\/?$/,'<span class="abbr"><span class="scheme">\k<scheme></span>\k<abbr></span><span class="frag">\k<frag></span>'
  end
  def html e=nil
    self
  end
end

class Fixnum
  def html e=nil; to_s end
  def max i; i > self ? self : i end
  def min i; i < self ? self : i end
end

class Float
  def html e=nil; to_s end
  def max i; i > self ? self : i end
  def min i; i < self ? self : i end
end

class TrueClass
  def html e=nil; H({_: :input, type: :checkbox, title: :True, checked: :checked}) end
end

class FalseClass
  def html e=nil; H({_: :input, type: :checkbox, title: :False}) end
end

class Hash
  def html e={'SERVER_NAME'=>'localhost'}
    if keys.size == 1 && has_key?('uri')
      uri.href
    else
      H({_: :table, class: :html, c: map{|k,v|
            {_: :tr, property: k, c:
              [k == R::Content ? {_: :td, class: :val, colspan: 2, c: v} :
               [{_: :td, c: (k == 'uri' ? {} : {_: :a, name: k, href: k, c: k.to_s.abbrURI}), class: :key},
                {_: :td, c: k == 'uri' ? v.R.do{|u| {_: :a, id: u, href: u.url, c: v}} : v.html(e), class: :val}]]}}})
    end
  end
end

class R

  def html *a
    url.href
  end

  View['select']=->d,e{
    d.map{|u,r|
      type = r[Type].justArray.find{|type|
        type.respond_to?(:uri) && View[type.uri]}
      View[type ? type.uri : 'base'][{u => r},e]}}

  View['base']=->d,e{[H.once(e,'base',H.css('/css/html')),d.values.map{|v|v.html e}]}

  View['title'] = -> g,e {
    [g.map{|u,r|
       {_: :a, href: u, c: r[Title]||u.R.basename}},
     {_: :style, c: "
a {font-size: 1.7em;font-weight:bold;text-decoration:none;background-color:#{R.cs};color:#fff;float:left;padding:.1em;margin:.1em}
"}
    ]}

  def triplrHref enc=nil
    yield uri, Content, H({_: :pre, style: 'white-space: pre-wrap', 
                            c: open(d).read.do{|r| enc ? r.force_encoding(enc).to_utf8 : r}.hrefs}) if f
  end

  def nokogiri;  Nokogiri::HTML.parse (open uri).read end

  def triplrHTML
    yield uri, Type, R[HTML]
    yield uri, Content, r
  end

  View[HTML]=->g,e{
    [H.once(e,'base',H.css('/css/html')),
     g.map{|u,r|
      {class: :HTML, c: [u.href,r[Content]]}}]}

  HTMLbody = -> b {
    b.to_s.split(/<body[^>]*>/)[-1].to_s.split(/<\/body>/)[0] }

  CleanHTML = -> b {
    h = Nokogiri::HTML.fragment HTMLbody[b]
    h.css('iframe').remove
    h.css('script').remove
    h.xpath("//@*[starts-with(name(),'on')]").remove
    h.to_s}

  View[HTTP+'Response'] = -> d,e { # HTTP-response data, such as page links
    d['#'].do{|u|
      path = e['REQUEST_PATH']
      qs = e['QUERY_STRING'].do{|qs|qs.empty? ? '' : '?' + qs} || ''
      [u[Prev].do{|p|{_: :a, rel: :prev, href: p.uri, c: '&larr;',style: 'color:#fff;background-color:#000;font-size:2.4em;float:left;clear:both'}},
       u[Next].do{|n|{_: :a, rel: :next, href: n.uri, c: '&rarr;',style: 'color:#000;background-color:#fff;font-size:2.4em;float:right;clear:both;'}},
       ({_: :a, rel: :nofollow, href: (path[-1] == '/' ? path + 'index.n3' : path.R.n3) + qs,
         c: {_: :img, src: '/css/misc/cube.png', style: 'float:right;height:2em;background-color:white;padding:.54em;border-radius:1em;margin:.2em'}} if path),
       ([(H.js '/js/pager'),(H.once e,:mu,(H.js '/js/mu'))] if u[Next]||u[Prev])]}} # (n)ext (p)rev

  Render['text/html'] = -> d,e { u = d['#']||{}
    titles = d.map{|u,r| r[Title] if r.class==Hash }.flatten.compact
    view = View[e.q['view']] || View['select']
    H ['<!DOCTYPE html>',{_: :html,
         c: [{_: :head, c: ['<meta charset="utf-8" />',
                   {_: :title, c: titles.size==1 ? titles[0] : e.uri},
                   {_: :link, rel: :icon, href:'/css/misc/favicon.ico'},
     u[Next].do{|n|{_: :link, rel: :next, href: n.uri}},
     u[Prev].do{|p|{_: :link, rel: :prev, href: p.uri}}]},
             {_: :body, c: view[d,e]}]}]}

  View['table'] = -> g,e {
    keys = g.values.select{|v|v.respond_to? :keys}.map(&:keys).flatten.uniq
    [H.css('/css/table'),
     {_: :table,:class => :tab,
       c: [{_: :tr, c: keys.map{|k|{_: :th, class: :label, property: k, c: k.abbrURI}}},
           g.values.map{|e|{_: :tr, about: e.uri, c: keys.map{|k| {_: :td, property: k, c: k=='uri' ? e.R.html : e[k].html}}}}]}]}

  View[COGS+'HiddenContainer'] = NullView

end
