# -*- coding: utf-8 -*-
#watch __FILE__

class String
  def hrefs i=false
    (partition /(https?:\/\/(\([^)]*\)|[,.]\S|[^\s),.”\'\"<>\]])+)/).do{|p|
      p[0].gsub('<','&lt;').gsub('>','&gt;')+
      (p[1].empty?&&''||'<a rel=untyped href='+p[1]+'>'+p[1].do{|p|
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

  fn 'view/monospace',->d,e{
    [(H.once e,'text',(H.css '/css/text')),
     d.values.map{|v|
      v[Content].do{|c|
        {class: :text,
           c: [{_: :a, href: v.url+'?view', c: v.label, style: "background-color:" + E.c},
               {_: :pre,  c: c }]}}}]}

  F['view/'+MIMEtype+'application/word']= F['view/monospace']
  F['view/'+MIMEtype+'blob']            = F['view/monospace']
  F['view/'+MIMEtype+'text/plain']      = F['view/monospace']
  F['view/'+MIMEtype+'text/rtf']        = F['view/monospace']

  fn 'view/'+MIMEtype+'text/nfo',->r,_{r.values.map{|r|{_: :pre,
      style: 'background-color:#000;padding:2em;color:#fff;float:left;font-family: "Courier New", "DejaVu Sans Mono", monospace; font-size: 13px; line-height: 13px',
        c: [{_: :a, 
              style: 'color:#0f0;font-size:1.1em;font-weight:bold', 
              c: r.E.bare, 
              href: r.uri+'?view=txt'},
            '<br>',r[Content]]}}}

  fn 'view/title',->d,e{
    i = F['view/title/item']
    [d.map{|u,r|[i.(r,e),' ']},
     (H.once e,'title',(H.css '/css/title'))
    ]}

  fn 'view/title/item',->r,e{
    {_: :a, class: :title, href: r.E.url,
      c: r[Title] || (Fn 'abbrURI', r.uri)}}

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
    d.map{|u,r|# each resource
      [u,"\n", # subject URI
       r.map{|k,v| # each predicate
         p = k.split(/[\/#]/)[-1]       # predicate
         k == 'uri' ||                  # already displayed
         [" "*(16-p.size).min(1),p," ", # align objects 
          (v.class==Array ? v:[v]).map{|v|# each object
            v.respond_to?(:uri) ? v.uri : # object-URI
            v.to_s.                       # object-content
            gsub(/<\/*(br|p|div)[^>]*>/,"\n").           # add linebreaks 
            gsub(/<a.*?href="*([^'">\s]+)[^>]*>/,'\1 '). # unwrap links
            gsub(/<[^>]+>/,'').                          # remove HTML
            gsub(/\n+/,"\n")}.                           # collapse empty space
          intersperse(' '),"\n"]},"\n"]}.join}           # collate

  fn Render+'text/uri',->d,_=nil{d.keys.join "\n"}

end
