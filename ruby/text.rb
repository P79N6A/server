# -*- coding: utf-8 -*-
#watch __FILE__

class String

  def h; Digest::SHA1.hexdigest self end

  def hrefs i=false
    #  ) only matches with an opener
    # ,. only match mid-URI
    (partition /(https?:\/\/(\([^)>\s]*\)|[,.]\S|[^\s),.”\'\"<>\]])+)/).do{|p|
      u = p[1] # URI
      p[0].gsub('<','&lt;').gsub('>','&gt;')+ # escape <> from pre-match
      (p[1].empty?&&''||'<a rel=untyped href="'+u+'">'+u.do{|p|
         i && p.match(/(gif|jpe?g|png|tiff)$/i) && # inline images if asked for
         "<img src=#{p}>" || p
       }+'</a>')+
      (p[2].empty?&&''||p[2].hrefs) # again on post-match tail
    }
  rescue
    self
  end

  def tail; self[1..-1] end
  def to_utf8
    encode('UTF-8', undef: :replace)
  rescue Encoding::InvalidByteSequenceError
    ""
  end
  def t; match(/\/$/) ? self : self+'/' end

end

class R

  fn 'view/monospace',->d,e{
    [(H.once e,'text',(H.css '/css/text')),
     d.values.map{|v|
      v[Content].do{|c|
         b = R.cs
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
    {_: :a, class: :title, href: r.R.url,
      c: r[Title] || r.uri.abbrURI} if (r.class == R || r.class == Hash) && r.uri}

  # a list of URIs
  def triplrUriList
    yield uri, COGS+'View', R[uri+'?view=csv']
    open(d).readlines.grep(/^[^#]/).map{|l|
      l = l.chomp
      yield uri, '/rel', l.R
      yield l, '/rev', self
      yield l, Type, R[CSV+'Row']
    }
  end

  def uris
    graph.keys.select{|u|u.match /^http/}.map &:R
  end

  def triplrANSI
    yield uri, Content, `cat #{sh} | aha`
  end

  def triplrMarkdown
    require 'markdown'
    yield uri,Content,Markdown.new(r).to_html
  end

  def triplrOrg
    require 'org-ruby'
    r.do{|r|
      yield uri,Content,Orgmode::Parser.new(r).to_html}
  end

  def triplrPDF &f
    triplrStdOut 'pdfinfo', &f
  end

  def triplrPS
    p = R[dirname + '/.' + File.basename(path) + '/']
    unless p.e
      p.mk
      `gs -dSAFER -dBATCH -dNOPAUSE -sDEVICE=png16m -r300 -sOutputFile='#{p.sh}%03d.png' -dTextAlphaBits=4 #{sh}`
    end
    yield uri, Content, `ps2txt #{sh}`.hrefs
    p.a('*.png').glob.map{|i|yield uri, DC+'Image', i}
  end

  F['view/'+MIMEtype+'application/postscript']=->r,e{
    [(H.once e, :mu,   (H.js '/js/mu')),(H.once e, :book, (H.js '/js/book')),
     {_: :style, c: 'div[type="book"] a {background-color:#ccc;color:#fff;float:left;margin:.16em}'},
     r.values.map{|d|
      d[DC+'Image'].do{|is|
        is = is.sort_by(&:uri)
        {type: :book,
          c: [{_: :img, style:'float:left;max-width:100%', src: is[0].url},
              {name: :pages,
                c: is.map{|i|{_: :a,href: i.url, c: i.R.bare}}}]}}}]}

  def triplrRTF
    yield uri, Content, `which catdoc && catdoc #{sh}`.hrefs
  end

  def triplrTeX
    yield uri, Content, `cat #{sh} | tth -r`
  end

  def triplrTextile; require 'redcloth'
    yield uri,Content,RedCloth.new(r).to_html
  end

  def triplrWord
    yield uri, Content, `which antiword && antiword #{sh}`.hrefs
  end

  fn Render+'text/plain',->d,_=nil{
    d.values.map{|r|
      [(r.map{|k,v|
        ["<",(k=='uri' ? '' : k),"> ", # predicate
         v.justArray.map{|v|# each object
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
