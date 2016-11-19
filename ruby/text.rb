# -*- coding: utf-8 -*-
#watch __FILE__

class String

  # HTML from plaintext
  def hrefs images=false, &b
    pre,link,post = self.partition R::Href
    u = link.noHTML # escape URI
    pre.noHTML +    # escape pre-match
      (link.empty? && '' || '<a href="' + u + '">' + # hyperlink
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
  #  ) only matches with an opener
  # ,. only match mid-URI
  Href = /(https?:\/\/(\([^)>\s]*\)|[,.]\S|[^\s),.”\'\"<>\]])+)/

  def R.pencil; ['&#x270e;','&#x270f;','&#x2710;'][rand(3)] end

  def triplrHTMLfragment
    yield uri, Content, r
  end

  def triplrHref enc=nil
    yield stripDoc.uri, Content,
    H({_: :pre, style: 'white-space: pre-wrap',
        c: open(pathPOSIX).read.do{|r|
          enc ? r.force_encoding(enc).to_utf8 : r}.hrefs}) if f
  end

  Render['text/uri-list'] = -> g,env {
    g.map{|subjURI,resource|
      resource[LDP+'contains'].justArray.map &:maybeURI
    }.flatten.compact.join "\n"}

  def uris
    graph.keys.select{|u|u.match /^http/}
  end

  def triplrMarkdown
    yield stripDoc.uri, Content, ::Redcarpet::Markdown.new(::Redcarpet::Render::Pygment, fenced_code_blocks: true).render(r) + H(H.css '/css/code')
  end

  def triplrOrg
    require 'org-ruby'
    yield stripDoc.uri, Content, Orgmode::Parser.new(r).to_html
  end

  def triplrPS
    u = stripDoc.uri
    yield u, Type, (R MIMEtype+'application/postscript')
    p = dir.child '.' + basename + '/'
    unless p.e
      p.mk
      `gs -dSAFER -dBATCH -dNOPAUSE -sDEVICE=png16m -r300 -sOutputFile='#{p.sh}%03d.png' -dTextAlphaBits=4 #{sh}`
    end
    p.children.map{|i|yield u, Image, i}
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
    yield stripDoc.uri, Content, `which catdoc && catdoc #{sh}`.hrefs
  end

  def triplrTeX
    yield stripDoc.uri, Content, `cat #{sh} | tth -r`
  end

  def triplrTextile
    require 'redcloth'
    yield stripDoc.uri, Content, RedCloth.new(r).to_html
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
    yield uri, Type, R[SIOC+'SourceCode']
    if size < 65535 # only inline small files
      yield uri, Content, '<div class=sourcecode>'+StripHTML[`source-highlight -f html -s #{m} -i #{sh} -o STDOUT`+'</div>',nil,nil]
    end
  end

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

  # two step process to enable otherwise crawlers could start littering /man on every host
  # 1) "mount" man-handler on host+path or just path (all enabled hosts):
  #  $SERVERROOT/local.rb:
  #   GET['localhost/man'] = Man
  #   GET['/man'] = Man
  # 2) mkdir hostname/man for cache storage and whitelisting
  Man = -> e,r {
    puts "man"
    graph = RDF::Graph.new
    uri = R['//'+r.host+r['REQUEST_URI']]
    manPath = '/usr/share/man'
    name = e.justPath.stripSlash.uri.sub(/^\/man/,'').tail || ''
    section = nil
    name.match(/^([0-9])(\/|$)/).do{|p| # optional section
      section = p[1]
      name = p.post_match}
    if q = r.q['q']
      [303,{'Location'=>'/man/'+q},[]]
    elsif !R['//'+r.host+'/man'].exist? # hostname/man must exist
      nil
    elsif name.empty?
      input = {Type => R[SearchBox]}
      [200,{'Content-Type' => 'text/html'},[Render['text/html'][{'/man' => input},r]]] 
    else

      superLang = r.q['lang'].do{|l| (l.split /[_-]/)[0] }
      lang = r.q['lang'].do{|l|'-L ' + l.sub('-','_').sh }
      man = `man #{lang} -w #{section} #{name.sh}`.lines[0]

      if !man || man.empty?
        [303,{'Location'=>'/man/'},[]]
      else
        man = man.chomp
        roff = man.R
        dir = R['//' + r.host + roff.dirname.sub(/.*\/share/,'')]
        res = dir.child roff.bare
        doc = res + '.e'
        path = Pathname man

        cached = path.exist? && doc.e && doc.m > path.stat.mtime
        if !cached
          uri = e.uri + '#'
          txt = res + '.txt'
          html = res + '.html'

          graph = {
            uri => {
              'uri' => uri,
              Title => name,
              Type => R[Purl+'ontology/bibo/Manual'],
              DC+'locale' => [],
              RDFs+'seeAlso' => [],
              SKOS+'related' => [],
              DC+'hasFormat' => [html, txt]}}

          locales = graph[uri][DC+'locale']

          localesAvail = Pathname(manPath).c.select{|p|p.basename.to_s.do{|b|!b.match(/^man/) && !b.match(/\./)}}.map{|p|File.basename p}.select{|l|
            File.exist? manPath + '/' + l + '/' + roff.uri.split('/')[-2..-1].join('/')}

          imagePath = dir.pathPOSIX + '/images'
          FileUtils.mkdir_p imagePath unless File.exist? imagePath

          preconv = %w{hu pt tr}.member?(superLang) ? "" : "-k"
          gzipped = man.match /\.gz$/
          bzipped = man.match /\.bz2$/
          catcompressed = if bzipped
                            "bz"
                          elsif gzipped
                            "z"
                          else
                            nil
                          end
          pageCmd = -> format,opts="" {"#{catcompressed}cat #{man} | groff #{preconv} -T #{format} -mandoc #{opts}"}

          page = `#{pageCmd['html',"-P -D -P #{imagePath}"]}`.to_utf8
          `#{pageCmd['utf8',"-t -P -u -P -b"]} > #{txt.sh}`

          body = Nokogiri::HTML.parse(page).css('body')[0]
          body ||= Nokogiri::HTML.parse('<body><body>').css('body')[0]
          # CSS
          body.add_child H H.css('/css/man')
          
          # webize image paths
          body.css('img').map{|i|
            p = R.unPOSIX i.attr 'src'
            i.replace H[{_: :img, src: p}]}
          body.css('font').map{|f|f.remove_attribute 'color'}

          body.xpath('//text()').map{|a| # HTMLize plain-text                                <b> wrapped command-refs
            a.replace a.to_s.gsub('&amp;','&').gsub('&gt;','>').gsub('&lt;','<').hrefs.gsub /\b([^<>\s(]+)\(/mi, '<b>\1</b>('}

          body.css('a').map{|a| # inspect links
            a.attr('href').do{|href|
              graph[uri][RDFs+'seeAlso'].push R[href] unless href.match(/^#/)}}

          # localization links
          locales.push r['REQUEST_PATH'].R unless localesAvail.empty?
          (body.css('h1')[0] ||
           body.css('p')[0]).
            do{|top|
              top.add_previous_sibling H localesAvail.map{|l|
                locale = r['REQUEST_PATH']+'?lang='+l
                locales.push R[locale]
                {_: :a, class: :lang, href: locale, c: l}}}

          # RDF + HTML command-refs
          body.css('b').map{|b|
            b.next.do{|n|
              n.to_s.match(/\(([0-9])\)(.*)/).do{|section|
                name, s = b.inner_text, section[1]
                n.replace section[2]
                linkPath = "/man/#{s}/#{name}"
                graph[uri][SKOS+'related'].push linkPath.R
                b.replace " <a href='#{linkPath}'><b>#{name}</b>(#{s})</a>"}}}

          html.w body.children.to_xhtml
          doc.w graph, true
        end

        res.setEnv(r).response
      end
    end
  }

end
