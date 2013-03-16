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
    H([{_: :a, name: uri},
       {_: :table, c: 
        map{|k,v|
          {_: :tr, property: k, c:
            [{_: :td,c: (Fn 'abbrURI',k), class: :key},
             {_: :td,c: v.html, class: :val}].cr}}.cr}].cr)
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
    u.to_s.sub(/(.*?)([^#\/]+)$/,'<span class=abbr>\1</span><span class=frag>\2</span>')}

  fn 'head',->d,e{
    [{_: :title, c: d.attr(Title) || e.uri},
     (Fn 'head.formats',e),
     (Fn 'head.icon')].cr}

  fn 'head.formats',->e{
    F.keys.grep(/^render/).map{|f|
      f = f[7..-1]
      {_: :link, rel: :alternate, type: f, href:'http://' + e['SERVER_NAME'] + e['REQUEST_PATH'] + e.q.merge({'format' => f}).qs}}.cr}

  fn 'head.icon',->{{_: :link, href:'/css/i/favicon.ico', rel: :icon}}

  fn 'view',->d,e{
    d.values.map{|r|Fn 'view/divine/item',r,e}}

  fn 'view/divine/item',->r,e{
    r.class==Hash &&
    r[Type] &&
    r[Type][0] &&
    r[Type][0].respond_to?(:uri) &&
    (t = r[Type][0].uri
     !t.empty? && 
     (F['view/'+t] ||
      F['view/'+t.split(/\//)[-2]]).do{|f|
       f.({r.uri => r},e)}) ||
    r.html }

  fn 'view/multi',->d,e{e.q['views'].split(',').map{|v|Fn'view/'+v,d,e}}

  def raw
    glob.select(&:f).do{|f|f.map{|r|
        yield r.uri,Type,E('blob')
        yield r.uri,Content,r.r}} end

  graphFromStream :raw

  def hyper e=nil
    yield uri,Content,read.do{|r|e ? r.force_encoding(e).to_utf8 : r}.hrefs
  end

  fn Render+'text/html',->d,e{
    v = e.q['view'].to_s
    h = F['head/'+v] || F['head'] 
    v = F['view/'+v] || F['view']

    H(e.q.has_key?('un') ? v.(d,e) :
      ['<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE HTML PUBLIC "-//W3C//DTD XHTML+RDFa 1.0//EN" "http://www.w3.org/MarkUp/DTD/xhtml-rdfa-1.dtd">',
       {_: :html,
         c: [{_: :head,
               c: ['<meta charset="utf-8" />',
                   h.(d,e)]},
             {_: :body, c: v.(d,e)}].cr}].cr)}

end
