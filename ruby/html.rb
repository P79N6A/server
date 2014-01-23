#watch __FILE__

# (H) templates
def H _
  case _
  when Hash
    '<'+(_[:_]||:div).to_s+(_.keys-[:_,:c]).map{|a|
      ' '+a.to_s+'='+"'"+_[a].to_s.chars.map{|c|{"'"=>'%27','>'=>'%3E','<'=>'%3C'}[c]||c}.join+"'"}.join+'>'+
      (_[:c] ? (H _[:c]) : '')+
      (_[:_] == :link ? '' : ('</'+(_[:_]||:div).to_s+'>'))
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
    inline ? {_: :script, c: p.E.r} :
    {_: :script, type: "text/javascript", src: p}
  end

  def H.css a,inline=false
    p = a + '.css'
    inline ? {_: :style, c: p.E.r} :
    {_: :link, href: p, rel: :stylesheet, type: E::MIME[:css]}
  end

  def H.once e,n,*h
    return if e[n]
    e[n]=true
    h
  end
end

class Array
  def html v=nil,g=nil
    map{|e|e.html v,g}.join ' '
  end
end

class Object
  def html *a
    name = self.class
    href = "https://duckduckgo.com/?q=ruby+#{name}"
    "<a href=#{href}><b>#{name}</b></a>"
  end
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
  def html e=nil,g=nil
    self
  end
end

class Fixnum
  def html e=nil,g=nil; to_s end
end

class Float
  def html e=nil,g=nil; to_s end
end

class TrueClass
  def html e=nil,g=nil; H({_: :input, type: :checkbox, title: :True, checked: :checked}) end
end

class FalseClass
  def html e=nil,g=nil; H({_: :input, type: :checkbox, title: :False}) end
end

IsBnode = /^_:/

class Hash
  def html e={'SERVER_NAME'=>'localhost'}, g={}, key=true
    if keys.size == 1 && has_key?('uri')
      if uri.match IsBnode
        g[uri].do{|r|
          r.html e,g,key } || uri.href
      else
        uri.href
      end
    else
      H({_: :table, class: :html, c: map{|k,v|
            unless k == 'uri' && (v.match IsBnode)
              {_: :tr, property: k, c:
                [k == E::Content ? {_: :td, class: :val, colspan: 2, c: v} :
                 [
                  ({_: :td, c: [{_: :a, name: k, href: (k == 'uri' ? v : k), c: k.to_s.abbrURI}], class: :key} if key),
                  {_: :td, c: k == 'uri' ? v.E.do{|u| {_: :a, id: u, href: u.url, c: v}} : v.html(e,g), class: :val},
                 ]]}
            end
          }})
    end
  end
end

class E

  def html *a
    url.href
  end

  fn 'view',->d,e{
    d.values.select{|r|
      !r.has_key?('uri') || # URI field missing
      !r.uri.match(IsBnode) # blank node
      true
    }.
    sort_by{|r| r[Date].do{|d| d[0].to_s} || ''}.reverse.
    map{|r| Fn 'view/select',r,e,d}.
    push(d.keys.grep(IsBnode).empty? ? [] : {_: :style, c: 'td.val .abbr {display: none}'})}

  fn 'view/base',->d,e,k=true,graph=nil{
    [H.once(e,'base',H.css('/css/html')),
     d.values.map{|v|v.html e,graph,k}]}

  fn 'view/select',->r,e,d{
    graph = {r.uri => r}
    view = nil
    if r.class == Hash
      (r[Type].class==Array ? r[Type] : [r[Type]]).do{|types|
        views = types.map{|t|
          # discard non-URIs
          t.uri if t.respond_to? :uri}.
        compact.map{|t|
          subtype = t
          type = subtype.split(/\//)[-2]
          [F['view/' + subtype],
          (F['view/' + type] if type)]}.
        flatten.compact
        view = views[0] unless views.empty?}
    end
    if !view # default view
      F['view/base'][graph,e,true,d]
    else
      view[graph,e]
    end}

  # enumerate available views
  fn 'view/?',->d,e{
    F.keys.grep(/^view\/(?!application|text\/x-)/).map{|v|
      v = v[5..-1] # eat selector
      [{_: :a, href: e['REQUEST_PATH']+e.q.merge({'view'=>v}).qs, c: v},"<br>\n"]}}

  def triplrBlob
    glob.select(&:f).do{|f|f.map{|r|
        yield r.uri,Type,E('blob')
        yield r.uri,Content,r.r}} end

  def triplrHref enc=nil
    yield uri,Content,(f && read).do{|r|enc ? r.force_encoding(enc).to_utf8 : r}.hrefs
  end

  require 'nokogiri'
  def nokogiri;  Nokogiri::HTML.parse read end

  def contentURIresolve *f
    send(*f){|s,p,o|
      yield s, p, p == Content ?
      (Nokogiri::HTML.parse o).do{|o|
        o.css('a').map{|a|
          if a.has_attribute? 'href'
            (a.set_attribute 'href', (URI.join s, (a.attr 'href'))) rescue nil
          end}
        o.to_s} : o}
  end

  fn Render+'text/html',->d,e{ u = d['#']||{}
    titles = d.map{|u,r| r[Title] if r.class==Hash }.flatten.compact
    view = F['view/'+e.q['view'].to_s] || F['view']
    H ['<!DOCTYPE html>',{_: :html,
         c: [{_: :head, c: ['<meta charset="utf-8" />',
                   {_: :title, c: titles.size==1 ? titles[0] : e.uri},
                   {_: :link, rel: :icon, href:'/css/misc/favicon.ico'},
     u[Next].do{|n|{_: :link, rel: :next, href: n.uri}},
     u[Prev].do{|p|{_: :link, rel: :prev, href: p.uri}}]},
             {_: :body, c: view[d,e]}]}]}

  # property-selector toolbar - utilizes RDFa view
  fn 'view/p',->d,e{
    #TODO fragmentURI scheme for selection-state
    [H.once(e,'property.toolbar',H.once(e,'p',(H.once e,:mu,H.js('/js/mu')),
     H.js('/js/p'),
     H.css('/css/table')),
     {_: :a, href: '#', c: '-', id: :hideP},
     {_: :a, href: '#', c: '+', id: :showP},
     {_: :span, id: 'properties',
       c: E.graphProperties(d).map{|k|
         {_: :a, class: :n, href: k, c: k.label+' '}}},
       {_: :style, id: :pS},
       {_: :style, id: :lS}),
     (Fn 'view/'+(e.q['pv']||'table'),d,e)]}

  # table-cell placement on sparse matrix of rows/columns
  # cal.rb contains an example usage
  fn 'view/t',->d,e,l=nil,a=nil{
    layout = e.q['table'] || l
    if layout
      [H.once(e,'table',H.css('/css/table')),
       {_: :table, c:
         {_: :tbody, c: (Fn 'table/'+layout,d).do{|t|
             rx = t.keys.max
             rm = t.keys.min
             c = t.values.map(&:keys)
             cm = c.map(&:min).min
             cx = c.map(&:max).max
             rm && rx && (rm..rx).map{|r|
               {_: :tr, c: 
                 t[r].do{|r|
                   (cm..cx).map{|c|
                     r[c].do{|c|
                       {_: :td, class: :cell, c:(Fn 'view/'+(a||e.q['cellview']||'title'),c,e)}
                     }||{_: :td}}}}} || ''
           }}}]
    else
      "table= layout arg required"
    end}

  fn 'view/table',->g,e{
    keys = E.graphProperties g
    v = g.values
    e.q['sort'].do{|p|
      p = p.expand
      v = v.sort_by{|s|
        s[p].do{|o|
          o[0].to_s}||''}} # cast to a single type (String) so sort will work. every class seems to have a #to_s
    v = v.reverse if e.q['reverse']
    [H.css('/css/table'),
     {_: :table,:class => :tab,
       c: [{_: :tr, c: keys.map{|k|{_: :th, class: :label, property: k, c: k.abbrURI}}},
           v.map{|e|{_: :tr, about: e.uri, c: keys.map{|k| {_: :td, property: k, c: k=='uri' ? e.E.html : e[k].html}}}}]}]}

end
