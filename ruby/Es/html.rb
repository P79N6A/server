#watch __FILE__

def H _
  # Ruby object-literal syntax as HTML constructors
  case _
  when Hash then
    '<'+(_[:_]||:div).to_s+(_.keys-[:_,:c]).map{|a|
      ' '+a.to_s+'='+"'"+
      _[a].to_s.hsub({"'"=>'%27',
                       '>'=>'%3E',
                       '<'=>'%3C'})+"'"}.join+'>'+
      (_[:c] ? (H _[:c]) : '')+
      (_[:_] == :link ? '' : ('</'+(_[:_]||:div).to_s+'>'))
  when Array then
    _.map{|n|H n}.join
  else
    _.to_s
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
  def html table=true
    map(&:html).join ' '
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
    '<a href="'+self+'">'+(name||(Fn 'abbrURI',self))+'</a>'
  end
  def html
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
  def html; H({_: :input, type: :number, value: to_s}) end
end

class Float
  def html; H({_: :input, type: :number, value: to_s}) end
end

class TrueClass
  def html; H({_: :input, type: :checkbox, title: :True, checked: :checked}) end
end

class FalseClass
  def html; H({_: :input, type: :checkbox, title: :False}) end
end

class Hash
  def html
    H({_: :table, class: :html, c: 
        map{|k,v|
          {_: :tr, property: k, c:
            [{_: :td,
               c: {_: :a, name: k,
                 href: (k == 'uri' ? v : k),
                 c: (Fn 'abbrURI',k)}, class: :key},
             {_: :td,
               c: (case k
                   when E::Content
                     {_: :pre, style: "white-space: pre-wrap", c: v}
                   when 'uri'
                     u = v.E
                     {_: :a, id: u, href: u.url, c: v}
                   else
                     v.html
                   end), class: :val}].cr}}.cr})
  end
end

class E
  def html name=nil,l=false
      (l ? url : uri).href name
   end

  def link
    html '#',true
  end

  fn 'abbrURI',->u{
    u.to_s.sub(/(?<scheme>[a-z]+:\/\/)?(?<abbr>.*?)(?<frag>[^#\/]*)$/,
     '<div class="abbr"><div class="scheme">\k<scheme></div>\k<abbr></div><div class="frag">\k<frag></div>')}

  fn 'head',->d,e{
    [{_: :title, c: e.uri},
     (Fn 'head.formats',e),
     (Fn 'head.icon')].cr}

  fn 'head.formats',->e{
    formats = %w{application/json text/n3}
    formats.map{|f|
      {_: :link, rel: :meta, type: f,
        href:'http://' + e['SERVER_NAME'] + e['REQUEST_PATH'] + e.q.merge({'format' => f}).qs}}.cr}

  fn 'head.icon',->{{_: :link, href:'/css/misc/favicon.ico', rel: :icon}}

  # domain-specific view
  fn 'view',->d,e{( Fn 'view/divine/set',d,e)||
    d.values.map{|r|Fn 'view/divine/item',r,e}}

  # no domain-specific view
  fn 'view/base',->d,e{
    [H.once(e,'base',H.css('/css/html')),
     d.values.map(&:html)]}

  # select domain-view - filename inspect
  fn 'view/divine/set',->d,e{
    d.values.map{|e|e.E.base}.do{|b|
      s = b.size.to_f
      t = 0.42 # threshold
      if b.grep(/^msg\./).size / s > t
        Fn 'view/threads',d,e
      elsif b.grep(AudioFile).size / s > t
        Fn 'view/audio', d,e
      elsif b.grep(/(gif|jpe?g|png)$/i).size / s > t
        Fn 'view/th', d,e
      elsif b.grep(/\.log$/).size / s > t
        Fn 'view/chat', d,e
      else false
      end}}

  # select domain-view - RDF-type inspect
  fn 'view/divine/item',->r,e{
    r.class == Hash &&
    r[Type] &&
    r[Type][0] &&
    r[Type][0].respond_to?(:uri) &&
    (t = r[Type][0].uri # RDF type
     (F['view/'+t] ||
      F['view/'+t.split(/\//)[-2]]).do{|f|
       f.({r.uri => r},e)}) ||
    [r.html,H.once(e,'css',H.css('/css/html'))] }

  # multiple views (comma-separated)
  fn 'view/multi',->d,e{e.q['views'].split(',').map{|v|Fn'view/'+v,d,e}}

  def triplrBlob
    glob.select(&:f).do{|f|f.map{|r|
        yield r.uri,Type,E('blob')
        yield r.uri,Content,r.r}} end

  def triplrHref enc=nil
    puts "triplrHref #{uri} #{d}"
    yield uri,Content,(f && read).do{|r|enc ? r.force_encoding(enc).to_utf8 : r}.hrefs
  end

  fn Render+'text/html',->d,e{
    v = e.q['view'].to_s
    h = F['head/'+v] || F['head'] 
    v = F['view/'+v] || F['view']
    H(e.q.has_key?('un') ? v[d,e] :
      ['<!DOCTYPE html>',
       {_: :html,
         c: [{_: :head,
               c: ['<meta charset="utf-8" />',
                   h[d,e]]},
             {_: :body, c: v[d,e]}].cr}].cr)}

  
  # property-selector toolbar (requires RDFa views)
  fn 'view/p',->d,e{
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
    [H.once(e,'table',H.css('/css/table')),
     {_: :table, c:
     {_: :tbody, c: (Fn 'table/'+(l||e.q['table']),d).do{|t|
          rx = t.keys.max
          rm = t.keys.min
          c = t.values.map(&:keys)
          cm = c.map(&:min).min
          cx = c.map(&:max).max
          (rm..rx).map{|r|
            {_: :tr, c: 
              t[r].do{|r|
                (cm..cx).map{|c|
                  r[c].do{|c|
                    {_: :td, class: :cell, c:(Fn 'view/'+(a||e.q['cellview']),c,e)}
                    }||{_: :td}}}}}}}}]}

  fn 'view/table',->i,e{[H.css('/css/table'),(Fn 'table',i.values,e)]}

  fn 'table',->es,q=nil{
    ks = {} # predicate table
    es.map{|e|e.respond_to?(:keys) &&
              e.keys.map{|k|ks[k]=true}}
    keys = ks.keys
    keys.empty? ? es.html :
    H({_: :table,:class => :tab,
        c: [{_: :tr,
              c: keys.map{|k|
                {_: :th, class: :label, property: k,
                  c: q ? {_: :a,
                    href: q['REQUEST_PATH']+q.q.except('reverse').merge({'sort'=>k}).merge(q.q.member?('reverse') ? {} : {'reverse'=>true}).qs,
                    c: (Fn 'abbrURI',k)} : k}}},
            *es.map{|e|
              {_: :tr, about: e.uri, c:
                keys.map{|k|
                  {_: :td, property: k, c: e[k].do{|v|
                      (v.class==Array ? v : [v]).map(&:html).join ' '}}}}}]})}

end
