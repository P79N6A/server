#watch __FILE__

class Array
  def html table=true
    map(&:html).join ' '
  end
end

class Object
  def html *a
    name = self.class
    href = "http://www.ruby-doc.org/core/#{name}.html"
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
            [{_: :td,c: {_: :a, name: k, href: k, c: (Fn 'abbrURI',k)}, class: :key},
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
    [{_: :title, c: d.attr(Title) || e.uri},
     (Fn 'head.formats',e),
     (Fn 'head.icon')].cr}

  fn 'head.formats',->e{
    formats = %w{application/json text/n3}
#   formats = F.keys.grep(/^render/).map{|f|f[7..-1]} # all
    formats.map{|f|
      {_: :link, rel: :meta, type: f,
        href:'http://' + e['SERVER_NAME'] + e['REQUEST_PATH'] + e.q.merge({'format' => f}).qs}}.cr}

  fn 'head.icon',->{{_: :link, href:'/css/i/favicon.ico', rel: :icon}}

  # type-specific view
  fn 'view',->d,e{( Fn 'view/divine/set',d,e)||
    d.values.map{|r|Fn 'view/divine/item',r,e}}

  # no domain-specific view
  fn 'view/base',->d,e{
    [H.once(e,'base',H.css('/css/html')),
     d.values.map(&:html)]}

  # select view - filesystem hints
  fn 'view/divine/set',->d,e{
    d.values.map{|e|e.E.base}.do{|b|
      s = b.size.to_f
      t = 0.42 # threshold
   if b.grep(/^msg\./).size / s > t # email
      Fn 'view/threads',d,e
elsif b.grep(/(aif|wav|flac|mp3|m4a|aac|ogg)$/i).size / s > t # audio
      Fn 'view/audioplayer', d,e
elsif b.grep(/(gif|jpe?g|png)$/i).size / s > t # images
      Fn 'view/th', d,e
elsif b.grep(/\.log$/).size / s > t
      Fn 'view/chat', d,e
 else false
   end}}

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

  # display multiple views (comma-separated)
  fn 'view/multi',->d,e{e.q['views'].split(',').map{|v|Fn'view/'+v,d,e}}

  # show available views
  fn 'view/?',->d,e{
    [{_: :style, c: 'a {min-width:22em;text-align:right}'},
    F.keys.grep(/^view\/(?!application)/).map{|v|
      [{_: :a, href: e['REQUEST_PATH']+e.q.merge({'view' => v[5..-1]}).qs,c: v},'<br>']}]}

  def triplrBlob
    glob.select(&:f).do{|f|f.map{|r|
        yield r.uri,Type,E('blob')
        yield r.uri,Content,r.r}} end
  graphFromStream :triplrBlob

  def triplrHref e=nil
    yield uri,Content,read.do{|r|e ? r.force_encoding(e).to_utf8 : r}.hrefs
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

end
