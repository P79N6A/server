# -*- coding: utf-8 -*-
#watch __FILE__

class String

  # text to HTML
  def hrefs i=false
    #  ) only matches with an opener
    # ,. only match mid-URI
    # URI can span lines since some software injects linebreaks
    (partition /(https?:\/\/(\([^)>\s\n]*\)|[,.\n]\S|[^\s),.”\'\"<>\]])+)/).do{|p|
      u = p[1].gsub "\n",'' # discard captured line-breaks
      p[0].gsub('<','&lt;').gsub('>','&gt;')+ # escape <>
      (p[1].empty?&&''||'<a rel=untyped href="'+u+'">'+u.do{|p|
         i && p.match(/(gif|jpe?g|png|tiff)$/i) && # inline images if asked for
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
         b = E.cs
        {class: :text,
           c: [{_: :a, href: v.url+'?view', c: v.label, style: "background-color:" + b},
               {_: :pre,  c: c, style: "border-color:" + b}]}}}]}

  F['view/'+MIMEtype+'application/word']= F['view/monospace']
  F['view/'+MIMEtype+'blob']            = F['view/monospace']
  F['view/'+MIMEtype+'text/plain']      = F['view/monospace']
  F['view/'+MIMEtype+'text/rtf']        = F['view/monospace']

  fn 'view/'+MIMEtype+'text/nfo',->r,_{r.values.map{|r|{_: :pre,
      style: 'background-color:#000;padding:2em;color:#fff;float:left;font-family: "Courier New", "DejaVu Sans Mono", monospace; font-size: 13px; line-height: 13px',
        c: [{_: :a, 
              style: 'color:#0f0;font-size:1.1em;font-weight:bold', 
              href: r.url, c: r.uri},'<br>',
            r[Content]]}}}

  fn 'view/title',->d,e{
    i = F['itemview/title']
    [d.map{|u,r|[i.(r,e),' ']},
     (H.once e,'title',(H.css '/css/title'))]}

  fn 'itemview/title',->r,e{
    {_: :a, class: :title, href: r.E.url,
      c: r[Title] || r.uri.abbrURI} if (r.class == E || r.class == Hash) && r.uri}

  # linebreak-delimited list of URIs
  def triplrUriList
    open(d).readlines.grep(/^[^#]/).map{|l|
      l = l.chomp
      yield uri, '/rel', l
      yield   l, '/rev', uri
    }
  end

  def uris
    graph.keys.map &:E
  end

  def triplrANSI
    yield uri, Content, `cat #{sh} | aha`
  end

  def triplrPDF &f
    triplrStdOut 'pdfinfo', &f
  end

  def triplrRTF
    yield uri, Content, `which catdoc && catdoc #{sh}`.hrefs
  end

  def triplrWord
    yield uri, Content, `which antiword && antiword #{sh}`.hrefs
  end

  def triplrTeX
    yield uri, Content, `cat #{sh} | tth -r`
  end

  fn Render+'text/plain',->d,_=nil{
    d.values.map{|r|
      [(r.map{|k,v|
        ["<",(k=='uri' ? '' : k),"> ", # predicate
         (v.class==Array ? v:[v]).map{|v|# each object
           v.respond_to?(:uri) ? '<'+(v.uri||'')+'>' : # object-URI
           v.to_s.                       # object-content
           gsub(/<\/*(br|p|div)[^>]*>/,"\n").           # add linebreaks 
           gsub(/<a.*?href="*([^'">\s]+)[^>]*>/,'<\1> '). # unwrap links
           gsub(/<[^>]+>/,'').                          # remove HTML
           gsub(/\n+/,"\n")}.                           # collapse empty space
         intersperse(' '),"\n"]} if r.class==Hash),"\n"]}.join} # collate

  F['view/text/plain']=->d,e{
    {_: :pre, c: F[Render+'text/plain'][d,e]}}

  fn Render+'text/uri',->d,_=nil{d.keys.join "\n"}

end
