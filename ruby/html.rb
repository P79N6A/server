#watch __FILE__

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
    p=a+'.js'
    inline ? {_: :script, c: p.E.r} :
    {_: :script, type: "text/javascript", src: p}
  end

  def H.once e,n,*h
    return if e[n]
    e[n]=true
    h
  end
end

class Array
  def html v=nil
    map{|e|e.html v}.join ' '
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
    sub /(?<scheme>[a-z]+:\/\/)?(?<abbr>.*?)(?<frag>[^#\/]*)$/,
    '<span class="abbr"><span class="scheme">\k<scheme></span>\k<abbr></span><span class="frag">\k<frag></span>'
  end
  def html e=nil
    if match /\A(\/|http)[\S]+\Z/
      href
    else
      self
    end
  rescue
    self
  end
end

class Fixnum
  def html e=nil; H({_: :input, type: :number, value: to_s}) end
end

class Float
  def html e=nil; H({_: :input, type: :number, value: to_s}) end
end

class TrueClass
  def html e=nil; H({_: :input, type: :checkbox, title: :True, checked: :checked}) end
end

class FalseClass
  def html e=nil; H({_: :input, type: :checkbox, title: :False}) end
end

class Hash
  def html e={'SERVER_NAME'=>'localhost'},key=true
    (keys.size == 1 && has_key?('uri')) ? url.href : 
      H({_: :table, class: :html, c:
        map{|k,v|
          {_: :tr, property: k, c:
           [({_: :td,
               c: [{_: :a, name: k, href: (k == 'uri' ? v : k), c: k.to_s.abbrURI}], class: :key} if key),
             {_: :td,
               c: (case k
                   when E::Content
                     {_: :pre, style: "white-space: pre-wrap", c: v}
                   when 'uri'
                     u = v.E
                     {_: :a, id: u, href: u.url, c: v}
                   else
                     v.html e
                   end), class: :val}]}}})
  end
end

class E

  def html *a
    url.href
  end

  fn 'view/select',->d,e{
    d.values.map{|r|Fn 'view/divine/resource',r,e}}

  # default view
  F['view'] = F['view/select']

  fn 'view/base',->d,e,k=true{
    [H.once(e,'base',H.css('/css/html')),
     d.values.map{|v|v.html e,k}]}

  # select a view for a RDF resource
  fn 'view/divine/resource',->r,e{
    graph = {r.uri => r}
    view = F['view/base']
    # find types, skipping malformed/missing info
    if r.class == Hash
      [*r[Type]].do{|types|
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
    view[graph,e]}

  # multiple views (comma-separated)
  fn 'view/multi',->d,e{
    e.q['views'].do{|vs|
      vs.split(',').map{|v|
        F['view/'+v].do{|f|f[d,e]}}}}

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
    puts "triplrHref #{uri} #{d}"
    yield uri,Content,(f && read).do{|r|enc ? r.force_encoding(enc).to_utf8 : r}.hrefs
  end

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

  # property-selector toolbar - requires RDFa view
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

  fn 'view/table',->i,e{[H.css('/css/table'),(Fn 'table',i.values,e)]}

  fn 'table',->es,q=nil{
    ks = {} # predicate table
    es.map{|e|e.respond_to?(:keys) &&
              e.keys.map{|k|ks[k]=true}}
    keys = ks.keys
    keys.empty? ? es.html :
    H({_: :table,:class => :tab,
        c: [{_: :tr, c: keys.map{|k|
                {_: :th, class: :label, property: k, c: k.abbrURI}}},
            *es.map{|e|
              {_: :tr, about: e.uri, c:
                keys.map{|k| {_: :td, property: k, c: e[k].html}}}}]})}

end
