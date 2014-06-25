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

  View['HTML']=->d,e{ # default, dispatch on RDF type
    e[:Graph] = d
    d.map{|u,r|
      type = r[Type].justArray.find{|type| type.respond_to?(:uri) && View[type.uri]}
      View[type ? type.uri : 'base'][{u => r},e]}}

  View['base']=->d,e{[(d.values.map &:html), # boring view
                      H.once(e,'base',H.css('/css/html',true))]}

  View['title'] = -> g,e {[{_: :style, c: "a {text-decoration: none; border: .1em dotted #aaf; float: left; margin:.1em; font-size: 1.4em}"},
                           g.map{|u,r| {_: :a, href: u, c: r[Title] || u}}]}

  def triplrHref enc=nil
    yield uri, Content, H({_: :pre, style: 'white-space: pre-wrap',
                            c: open(d).read.do{|r| enc ? r.force_encoding(enc).to_utf8 : r}.hrefs}) if f
  end

  def nokogiri;  Nokogiri::HTML.parse (open uri).read end

  def triplrHTML
    yield uri, Type, R[HTML]
    yield uri, Content, r
  end

  View[HTML]=->g,e{ # HTML fragment
    [H.once(e,'base',H.css('/css/html')),
     g.map{|u,r| {class: :HTML, c: r[Content]}}]}

  CleanHTML = -> b {
    h = Nokogiri::HTML.fragment b
    h.css('iframe').remove
    h.css('script').remove
    h.traverse{|e|e.attribute_nodes.map{|a|a.unlink unless %w{alt class color href rel src title type}.member? a.name}}
    h.to_xhtml}

  def offset # human-readable
    (query_values.do{|q| q['offset'].do{|o| o.R.stripDoc}} ||
     self).hierPart.split('/').join(' ')
  end

  View[LDP+'Resource'] = -> d,e {
    d['#'].do{|u|
      [u[Prev].do{|p|
         {_: :a, rel: :prev, href: p.uri,
           c: [{class: :arrow, c: '&larr;'},{class: :uri, c: p.R.offset}]}},
       u[Next].do{|n|
         {_: :a, rel: :next, href: n.uri,
           c: [{class: :uri, c: n.R.offset},{class: :arrow, c: '&rarr;'}]}},
       ([(H.css '/css/page', true), (H.js '/js/pager', true), (H.once e,:mu,(H.js '/js/mu', true))
        ] if u[Next]||u[Prev])]}} # (n)ext (p)rev

  View[LDP+'BasicContainer'] = -> i,e {
    [(H.once e, 'container', (H.css '/css/container')),
     i.map{|u,r| resource = r.R
       {class: :dir, style: "background-color: #{R.cs}",
         c: [resource.descend.href(('' if resource == '#')),
             r[LDP+'firstPage'].do{|p|p[0].R.href '⌦'},
             r[LDP+'contains'].do{|c|c.map{|c|c = c.R
                 label = e[:Graph][c.uri].do{|r|r[Label]}
                 [(c.href label),' ']}}]}}]}

  Render['text/html'] = -> d,e { u = d['#']||{}
    titles = d.map{|u,r|r[Title] if r.class==Hash}.flatten.select{|t|t.class==String}
    H ['<!DOCTYPE html>',{_: :html,
         c: [{_: :head, c: ['<meta charset="utf-8" />',
                  ({_: :title, c: titles.head} if titles.size==1),
                   {_: :link, rel: :icon, href:'/css/misc/favicon.ico'},
     u[Next].do{|n|{_: :link, rel: :next, href: n.uri}},
     u[Prev].do{|p|{_: :link, rel: :prev, href: p.uri}}]},
             {_: :body, c: (View[e.q['view']] || View['HTML'])[d,e]}]}]}

  View['table'] = -> g,e {
    keys = g.values.select{|v|v.respond_to? :keys}.map(&:keys).flatten.uniq
    [H.css('/css/table'),
     {_: :table,:class => :tab,
       c: [{_: :tr, c: keys.map{|k|{_: :th, class: :label, property: k, c: k.R.abbr}}},
           g.values.map{|e|{_: :tr, about: e.uri, c: keys.map{|k| {_: :td, property: k, c: k=='uri' ? e.R.html : e[k].html}}}}]}]}

  Prototypes = { # suggested predicates for resource
    SIOCt+'MicroblogPost' => [Content],
    SIOCt+'BlogPost' => [Title, Content],
    SIOCt+'WikiArticle' => [Title, Content]}

  View['edit'] = -> g,e { # in-<form> RDF-editor

    triple = ->s,p,o{ # triple -> <input>
      obj = o && s.R.predicatePath(p).objectPath(o)[0].uri # object URI
      t = CGI.escape [s,p,obj].to_json # s,p,o -> <input> name
      [(case p.R.uri
        when Content
          [{_: :textarea, name: t, c: o, rows: 16, cols: 80}, # <textarea>
           '<br>',o]
        when Date
          {_: :input, name: t, type: :datetime, value: !o || o.empty? && Time.now.iso8601 || o} # <input type=datetime>
        else
          {_: :input, name: t, value: o.respond_to?(:uri) ? o.uri : o, size: 54} # <input>
        end),"<br>\n"]}

    ps = [] # editable predicates
    e.q['prototype'].do{|pr| pr = pr.expand
      Prototypes[pr].do{|v|ps.concat v }} # prototype-resource predicates
    e.q['predicate'].do{|p|ps.push p }    # explicit predicate
    mono = e.q.has_key? 'mono' # one-object-per-predicate?

    [H.css('/css/html'), {_: :form, name: :editor, method: :POST, action: e['REQUEST_PATH'], # <form>
       c: [{_: :a, class: :edit, c: 'add predicate', href: e['REQUEST_PATH']+'?view=addProperty&new'}, # add predicate
          g.map{|s,r| {_: :table, class: :html, # each resource
               c: [{_: :tr, c: {_: :td, colspan: 2, c: {_: :a, class: :uri, id: s, c: s, href: s}}}, # subject URI
                   r.keys.except('uri').concat(ps).uniq.map{|p| # each predicate
                     {_: :tr,
                       c: [{_: :td, class: :key, c: {_: :a, title: p, href: p, c: p.R.abbr}}, # predicate URI
                           {_: :td, c: [r[p].do{|o|       # object(s)
                                   o.justArray.map{|o|    # each object
                                     triple[s,p,o]}},     # editable triple
                                 (triple[s,p,nil] unless mono && r[p]) # blank <input>
                                ]}]}}]} unless s=='#'},
          ({_: :input, type: :hidden, name: :mono, value: :true} if mono),
           {_: :input, type: :submit, value: 'save'}]}]}

  View['addProperty'] = -> g,e {
    [[Date,Title,Creator,Content,Label].map{|p| # links to common predicates
       [{_: :a, href: e['REQUEST_PATH']+{'predicate' => p, 'view' => 'edit', 'new' => 'new'}.qs, c: p},
        '<br>']},
     {_: :form, action: e['REQUEST_PATH'], method: :GET,
       c: [{_: :input, type: :url, name: :predicate, pattern: '^http.*$', size: 64},
           {_: :input, type: :hidden, name: :view, value: :edit},
           {_: :input, type: :hidden, name: :new, value: :new},
           {_: :input, type: :submit, value: 'property'}]}]}

end
