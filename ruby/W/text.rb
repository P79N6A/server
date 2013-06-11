# -*- coding: utf-8 -*-

class Array
  def text
    map(&:text).join ' '
  end
end

class String
  def text
    self
  end
  def hrefs i=false
    (partition /(https?:\/\/(\([^)]*\)|[,.]\S|[^\s),.”\'\"<>\]])+)/).do{|p|
      p[0].gsub('<','&lt;').gsub('>','&gt;')+
      (p[1].empty?&&''||'<a href='+p[1]+'>'+p[1].do{|p|
         i && p.match(/(gif|jpg|png|tiff)$/i) &&
         "<img src=#{p}>" || p
       }+'</a>')+
      (p[2].empty?&&''||p[2].hrefs)
    }
  rescue
    self
  end
  def camelToke
    scan /[A-Z]+(?=\b|[A-Z][a-z])|[A-Z]?[a-z]+/
  end
end

class Hash
  def text
    [map{|u,v|[u.to_s.camelToke,"\n",v.text,"\n"]},
     uri.do{|u|u.E.text},"\n"].join ' '
  end
end

class Object
  alias_method :text, :to_s
end

class E
  def camelToke; uri.camelToke end

  def text
    [uri, camelToke].text
  end

  fn 'view/c',->d,e{d.values.map{|v|v[Content]}}
  fn 'view/mono',->d,e{['<pre>',*(Fn 'view/c',d,e),'</pre>']}
  F['view/blob']=F['view/mono']
  F['view/text/plain']=F['view/mono']
  F['view/text/rtf']=F['view/mono']
  F['view/application/word']=F['view/mono']

  fn 'view/text/nfo',->r,_{r.values.map{|r|{_: :pre,
      style: 'background-color:#000;padding:2em;color:#fff;float:left;font-family: "Courier New", "DejaVu Sans Mono", monospace; font-size: 13px; line-height: 13px',
        c: [{_: :a, 
              style: 'color:#0f0;font-size:1.1em;font-weight:bold', 
              c: r.E.bare, 
              href: r.uri+'?view=txt'},
            '<br>',r[Content]]}}}
  F['view/txt']=F['view/text/nfo']

  fn 'view/title',->d,e{i=F['view/title/item']
    d.map{|u,r|[i.(r,e),' ']}}

  fn 'view/title/item',->r,e{{_: :a,href: r.E.url,c:r[e.q['title']||Title],class: :title}}

  def ansi
    yield uri, Content, `cat #{sh} | aha`
  end

  def rtf
    yield uri, Content, `which catdoc && catdoc #{sh}`.hrefs
  end

  def lines
    yield uri,'lineCount',wc
  end

  def word
    yield uri, Content, `which antiword && antiword #{sh}`.hrefs
  end

  fn Render+'text/plain',->d,_=nil{d.text}
  fn Render+'text/uri',->d,_=nil{d.keys.join "\n"}

end
