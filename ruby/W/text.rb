# -*- coding: utf-8 -*-
watch __FILE__

class String
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

class E

  fn 'view/c',->d,e{d.values.map{|v|v[Content]}}
  fn 'view/mono',->d,e{['<pre style="float:right;padding:.5em;color:#000;background-color:#fff">',*(Fn 'view/c',d,e),'</pre>']}
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

  # linebreak-delimited list of URIs
  def triplrUriList
    open(d).readlines.map{|l|
      l = l.chomp
      yield uri, '/link', l
      yield   l, '/link', uri
    }
  end

  # list of uris in a .u doc
  def uris
    graph.keys.map &:E
  end
  
  def triplrANSI
    yield uri, Content, `cat #{sh} | aha`
  end

  def triplrRTF
    yield uri, Content, `which catdoc && catdoc #{sh}`.hrefs
  end

  def triplrWord
    yield uri, Content, `which antiword && antiword #{sh}`.hrefs
  end

  fn Render+'text/plain',->d,_=nil{
    d.map{|u,r|
      [u,"\n", # URI
       r.map{|k,v| # each resource
         p = k.split(/[\/#]/)[-1]       # predicate
         [" "*(16-p.size).min(1),p," ", # align objects 
          [*v].map{|v|                  # each object
            v.respond_to?(:uri) ? v.uri : # object-URI
            v.to_s.                       # object-content
            gsub(/<\/*(br|p|div)[^>]*>/,"\n").           # add linebreaks 
            gsub(/<a.*?href="*([^'">\s]+)[^>]*>/,'\1 '). # unwrap links
            gsub(/<[^>]+>/,'').                          # remove HTML
            gsub(/\n+/,"\n")}.                           # collapse empty space
          intersperse(' '),"\n"]},"\n"]}.join}           # collate

  fn Render+'text/uri',->d,_=nil{d.keys.join "\n"}

end
