# -*- coding: utf-8 -*-
#watch __FILE__

class String

  # HTML from plaintext
  def hrefs images=false, &b
    pre,link,post = self.partition R::Href
    u = link.noHTML # escape URI
    pre.noHTML +    # escape pre-match
      (link.empty? && '' || '<a href="'+u+'">' + # hyperlink
       (if images && u.match(/(gif|jpe?g|png|webp)$/i) # image?
        yield(R::DC+'Image',u.R) if b # emit image-link tuple
        "<img src='#{u}'/>"           # inline image
       else
         yield(R::DC+'link',u.R) if b # emit link tuple
         u.sub(/^https?.../,'')       # text
        end) + '</a>') +
      (post.empty? && '' || post.hrefs(images,&b)) # process post-match tail
  end

  def noHTML
    gsub('&','&amp;').
    gsub('<','&lt;').
    gsub('>','&gt;')
  end

  def to_utf8
    encode('UTF-8', undef: :replace)
  rescue Encoding::InvalidByteSequenceError
    ""
  end

  def utf8
    force_encoding 'UTF-8'
  end

end

begin require 'redcarpet'
  module Redcarpet
    module Render
      class Pygment < HTML
        def block_code(code, lang)
          if lang
            IO.popen("pygmentize -l #{lang.downcase.sh} -f html",'r+'){|p|
              p.puts code
              p.close_write
              p.read
            }
          else
            code
          end
        end
      end
    end
  end
rescue LoadError => e
  puts e
end

class R
  # HTTP URIs in plain-text
  #  ) only matches with an opener
  # ,. only match mid-URI
  Href = /(https?:\/\/(\([^)>\s]*\)|[,.]\S|[^\s),.”\'\"<>\]])+)/

  def R.pencil; ['&#x270e;','&#x270f;','&#x2710;'][rand(3)] end

  def triplrContent
    yield uri+'#', Type, R[Content]
    yield uri+'#', Content, r
  end
  ViewGroup[Content] = -> d,_ {d.values.map{|r|r[Content]}}

  def triplrHref enc=nil
    yield uri+'#', Content,
    H({_: :pre, style: 'white-space: pre-wrap',
        c: open(pathPOSIX).read.do{|r|
          enc ? r.force_encoding(enc).to_utf8 : r}.hrefs}) if f
  rescue
    puts "error hyperlinking #{uri}"
    nil
  end

  Render['text/uri-list'] = -> g,env {
    g.map{|subjURI,resource|
      resource[LDP+'contains'].justArray.map &:maybeURI
    }.flatten.compact.join "\n"}

  def uris
    graph.keys.select{|u|u.match /^http/}
  end

  def triplrMarkdown
    yield uri+'#', Type, R[Content]
    yield uri+'#', Content, ::Redcarpet::Markdown.new(::Redcarpet::Render::Pygment, fenced_code_blocks: true).render(r) + H(H.css '/css/code')
  end

  def triplrOrg
    require 'org-ruby'
    yield uri+'#', Content, Orgmode::Parser.new(r).to_html
  end

  def triplrPS
    yield uri+'#', Type, (R MIMEtype+'application/postscript')
    p = dir.child '.' + basename + '/'
    unless p.e
      p.mk
      `gs -dSAFER -dBATCH -dNOPAUSE -sDEVICE=png16m -r300 -sOutputFile='#{p.sh}%03d.png' -dTextAlphaBits=4 #{sh}`
    end
    p.children.map{|i|yield uri+'#', Image, i}
  end

  ViewA[MIMEtype+'application/postscript']=->d,e{
    d[Image].do{|is|
      is = is.sort_by(&:uri)
      {type: :book,
       c: [{_: :img, style:'float:left;max-width:100%', src: is[0].uri},
           {name: :pages,
            c: is.map{|i|{_: :a,href: i.uri, c: i.R.bare}}}]}}}

  ViewGroup[MIMEtype+'application/postscript']=->g,e{
    [{_: :style, c: 'div[type="book"] a {background-color:#ccc;color:#fff;float:left;margin:.16em}'},
     (H.js '/js/book'),
      g.map{|u,r|
       ViewA[MIMEtype+'application/postscript'][r,e]}]}

  def triplrRTF
    yield uri+'#', Content, `which catdoc && catdoc #{sh}`.hrefs
  end

  def triplrTeX
    yield uri+'#', Content, `cat #{sh} | tth -r`
  end

  def triplrTextile
    require 'redcloth'
    yield uri+'#', Content, RedCloth.new(r).to_html
  end

  Render[WikiText] = -> texts {
    texts.justArray.map{|t|
      content = t[Content]
      case t['datatype']
      when 'markdown'
        ::Redcarpet::Markdown.new(::Redcarpet::Render::Pygment, fenced_code_blocks: true).render content
      when 'html'
        content
      when 'text'
        content.hrefs
      end}}

  def triplrSourceCode
    m = mime.split(/\//)[-1].sub(/^x-/,'')
    yield uri+'#', Type, R[SIOC+'SourceCode']
    if size < 128000 # skip huge source-code files
      yield uri+'#', Content, StripHTML[`source-highlight -f html -s #{m} -i #{sh} -o STDOUT`,nil,nil]
    end
  end

  ViewGroup[SIOC+'SourceCode'] = ViewGroup[BasicResource]

  %w{ada applescript asm awk bat bib bison caml changelog c clipper cobol conf cpp csharp
 desktop diff d erlang errors flex fortran function glsl haskell haxe java javascript
 key_string langdef latex ldap lisp logtalk lsm lua m4 makefile manifest nohilite
 number outlang oz pascal pc perl php prolog properties proto python ruby scala sh
 shellscript slang sml spec sql style symbols tcl texinfo todo vala vbscript}
    .map{|l|# ls /usr/share/source-highlight/*.lang | xargs -i basename {} .lang | tr "\n" " "
    ma = 'application/' + l
    mt = 'text/x-' + l
    MIME[l.to_sym] ||= ma # suffix -> MIME
    [ma,mt].map{|m| # MIME -> triplr
      MIMEsource[m] ||= [:triplrSourceCode]}}

  MIMEsource['text/css'] ||= [:triplrSourceCode]

end
