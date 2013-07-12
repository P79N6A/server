require 'element/H'
#watch __FILE__
class Array
  def html table=true
    if table && !find{|e|e.class != Hash} # monomorphic [Hash]
      Fn 'table',self
    else
      map(&:html).join ', '
    end
  end
end

class Object
  def html *a
    to_s.gsub('<','&lt;').gsub('>','&gt;')
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
    if match /^(https?:\/\/)[\S]+$/
      href
    else
      self
    end
  rescue
    self
  end
end

class Hash
  def html
    H({_: :table, c: 
        map{|k,v|
          {_: :tr, property: k, c:
            [{_: :td,c: (Fn 'abbrURI',k), class: :key},
             {_: :td,c: v.html, class: :val}].cr}}.cr})
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
    u.to_s.sub(/(.*?)([^#\/]+)$/,'<span class="abbr">\1</span><span class="frag">\2</span>')}

  fn 'head',->d,e{
    [{_: :title, c: d.attr(Title) || e.uri},
     (Fn 'head.formats',e),
     (Fn 'head.icon')].cr}

  fn 'head.formats',->e{
    F.keys.grep(/^render/).map{|f|
      f = f[7..-1]
      {_: :link, rel: :alternate, type: f, href:'http://' + e['SERVER_NAME'] + e['REQUEST_PATH'] + e.q.merge({'format' => f}).qs}}.cr}

  fn 'head.icon',->{{_: :link, href:'/css/i/favicon.ico', rel: :icon}}

  fn 'view',->d,e{( Fn 'view/divine/set',d,e)||
    d.values.map{|r|Fn 'view/divine/item',r,e}}

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

  Data['view/divine/item'] = "use RDF typeclass hints to choose view for a resource"
  fn 'view/divine/item',->r,e{
    r.class==Hash && r[Type] && r[Type][0] && r[Type][0].respond_to?(:uri) &&
    (t = r[Type][0].uri; !t.empty? && # a RDF type
     (F['view/'+t] ||
      F['view/'+t.split(/\//)[-2]]).do{|f|
       f.({r.uri => r},e)}) ||
    [r.html,H.once(e,'css',H.css('/css/html'))] }

  Data['view/select'] = "show a menu of all views available"
  fn 'view/select',->d,e{
    [{_: :style, c: 'a {min-width:22em;text-align:right}'},
    F.keys.grep(/^view\/(?!application)/).map{|v|
      [{_: :a, href: e['REQUEST_PATH']+e.q.merge({'view' => v[5..-1]}).qs,c: v},'<br>']}]}
   F['view/?'] = F['view/select']

  F['doc/view/multi'] = "display multiple comma-separated <b>views</b>"
  fn 'view/multi',->d,e{e.q['views'].split(',').map{|v|Fn'view/'+v,d,e}}

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

    H(e.q.has_key?('un') ? v.(d,e) :
      ['<!DOCTYPE html>',
       {_: :html,
         c: [{_: :head,
               c: ['<meta charset="utf-8" />',
                   h.(d,e)]},
             {_: :body, c: v.(d,e)}].cr}].cr)}

end
