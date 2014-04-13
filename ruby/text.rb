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
    graph.keys.select{|u|u.match /^http/}
  end

  def triplrMarkdown
    require 'redcarpet'
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
    yield uri, Type, (R MIMEtype+'application/postscript')
    p = R[dirname + '/.' + File.basename(path) + '/']
    unless p.e
      p.mk
      `gs -dSAFER -dBATCH -dNOPAUSE -sDEVICE=png16m -r300 -sOutputFile='#{p.sh}%03d.png' -dTextAlphaBits=4 #{sh}`
    end
#    yield uri, Content, `ps2txt #{sh}`.hrefs
    p.a('*.png').glob.map{|i|yield uri, DC+'Image', i}
  end

  View[MIMEtype+'application/postscript']=->r,e{
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

  def triplrSourceCode
    m = mime.split(/\//)[-1].sub(/^x-/,'')
    yield uri,Content, `source-highlight -f html -s #{m} -i #{sh} -o STDOUT` if size < 512e3
  end

  # ls /usr/share/source-highlight/*.lang | xargs -i basename {} .lang | tr "\n" " "
  %w{ada applescript asm awk bat bib bison caml changelog c clipper cobol conf cpp csharp css
 desktop diff d erlang errors flex fortran function glsl haskell haskell_literate haxe html java
 javascript key_string langdef latex ldap lisp log logtalk lsm lua m4 makefile manifest nohilite
 number outlang oz pascal pc perl php prolog properties proto python ruby scala sh
 shellscript slang sml spec sql style symbols tcl texinfo todo url vala vbscript xml}
    .map{|l|
    ma = 'application/' + l
    mt = 'text/x-' + l
    MIME[l.to_sym] ||= ma # extension mapping
    [ma,mt].map{|m| # triplr/view mappings
      MIMEsource[m] ||= [:triplrSourceCode]}}

  MIMEsource['text/css'] ||= [:triplrSourceCode] # i hear CSS is Turing complete now, http://inamidst.com/whits/2014/formats

  Render['text/plain'] = -> d, _ = nil {
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

  Render['text/uri'] = -> d, _ = nil {d.keys.join "\n"}

end
