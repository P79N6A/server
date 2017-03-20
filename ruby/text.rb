# -*- coding: utf-8 -*-
class String

  # HTML from plaintext
  def hrefs &b
    pre,link,post = self.partition R::Href
    u = link.noHTML # escape URI
    pre.noHTML +    # escape pre-match
      (link.empty? && '' || '<a id="t' + rand.to_s.h[0..3] + '" href="' + u + '">' + # hyperlink
       (if u.match(/(gif|jpe?g|png|webp)$/i) # image?
        yield(R::Image,u.R) if b # emit image as triple
        "<img src='#{u}'/>"           # inline image
       else
         yield(R::DC+'link',u.R) if b # emit hypertexted link
         u.sub(/^https?.../,'')       # text
        end) + '</a>') +
      (post.empty? && '' || post.hrefs(&b)) # process post-match tail
  end

  def noHTML
    gsub('&','&amp;').
    gsub('<','&lt;').
    gsub('>','&gt;')
  end

  def to_utf8
    encode('UTF-8', undef: :replace, invalid: :replace, replace: '?')
  end

  def utf8
    force_encoding 'UTF-8'
  end

end

require 'redcarpet'
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


class R
  # HTTP URIs in plain-text
  #  ) only matches with an opening (
  # ,. only match mid-URI as a URI seems to more often be used as a word in a sentence than end with those chars
  Href = /(https?:\/\/(\([^)>\s]*\)|[,.]\S|[^\s),.”\'\"<>\]])+)/

  def triplrHTMLfragment
    yield uri, Content, r
  end

  def triplrHref enc=nil
    id = stripDoc.uri
    yield id, Type, R[SIOC+'TextFile']
    yield id, Content,
    H({_: :pre, style: 'white-space: pre-wrap',
        c: open(pathPOSIX).read.do{|r|
          enc ? r.force_encoding(enc).to_utf8 : r}.hrefs}) if f
  end

  def triplrUriList
    open(pathPOSIX).readlines.map{|l|
      yield l.chomp, Type, R[Resource] }
  end

  def uris
    graph.keys.select{|u|u.match /^http/}.map &:R
  end

  def triplrMarkdown
    s = stripDoc.uri
    yield s, Type, R[SIOC+'MarkdownContent']
    yield s, Content, ::Redcarpet::Markdown.new(::Redcarpet::Render::Pygment, fenced_code_blocks: true).render(r) + H(H.css '/css/code')
  end

  def triplrOrg
    require 'org-ruby'
    yield stripDoc.uri, Content, Orgmode::Parser.new(r).to_html
  end

  def triplrCSV d
    lines = CSV.read pathPOSIX
    lines[0].do{|fields| # header-row
      yield uri, Type, R[CSVns+'Table']
      yield uri, CSVns+'rowCount', lines.size
      lines[1..-1].each_with_index{|row,line|
        row.each_with_index{|field,i|
          id = uri + '#row:' + line.to_s
          yield id, fields[i], field
          yield id, Type, R[CSVns+'Row']}}}
  end

  def triplrRTF
    yield stripDoc.uri, Content, `which catdoc && catdoc #{sh}`.hrefs
  end

  def triplrTeX
    yield stripDoc.uri, Content, `cat #{sh} | tth -r`
  end

  def triplrTextile
    require 'redcloth'
    yield stripDoc.uri, Content, RedCloth.new(r).to_html
  end

  def triplrSourceCode
    m = mime.split(/\//)[-1].sub(/^x-/,'')
    yield uri, Type, R[SIOC+'SourceCode']
    if size < 65535 # only inline small files
      yield uri, Content, '<div class=sourcecode>'+StripHTML[`source-highlight -f html -s #{m} -i #{sh} -o STDOUT`+'</div>',nil,nil]
    end
  end

  Abstract[SIOC+'TextFile'] = -> graph, subgraph, env {
    subgraph.map{|id,data|
      graph[id][DC+'hasFormat'] = R[id+'.html']
      graph[id][Content] = graph[id][Content].justArray.map{|c|c.lines[0..8].join}}}
  
  Abstract[SIOC+'SourceCode'] = -> graph, subgraph, re {
    full = re.q.has_key? 'full'
    re.env[:summarized] = true unless full
    subgraph.map{|id,source|
      html = id + '.html'
      graph[html] = source.update({DC+'formatOf' => R[id], 'uri' => html})
      graph.delete id
    } unless full
  }

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
