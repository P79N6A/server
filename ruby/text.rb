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
  #  ) only matches with an opener
  # ,. only match mid-URI
  Href = /(https?:\/\/(\([^)>\s]*\)|[,.]\S|[^\s),.”\'\"<>\]])+)/

  def R.pencil; ['&#x270e;','&#x270f;','&#x2710;'][rand(3)] end

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
    yield stripDoc.uri, Content, ::Redcarpet::Markdown.new(::Redcarpet::Render::Pygment, fenced_code_blocks: true).render(r) + H(H.css '/css/code')
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

  GET['/man'] = -> e {
    graph = RDF::Graph.new
    uri = R['//'+e.host+e.env['REQUEST_URI']]
    manPath = '/usr/share/man'
    name = e.justPath.stripSlash.uri.sub(/^\/man/,'').tail || ''
    section = nil
    name.match(/^([0-9])(\/|$)/).do{|p| # section (optional)
      section = p[1]
      name = p.post_match}
    if q = e.q['q']
      [303,{'Location'=>'/man/'+q},[]]
    elsif !R['//'+e.host+'/man'].exist? # ./domain/hostname/man must be created by administrator
      nil
    elsif name.empty?
      [200,{'Content-Type' => 'text/html'},[H[SearchBox[e]]]] 
    else

      superLang = e.q['lang'].do{|l| (l.split /[_-]/)[0] }
      lang = e.q['lang'].do{|l|'-L ' + l.sub('-','_').sh }
      man = `man #{lang} -w #{section} #{name.sh}`.lines[0]

      if !man || man.empty?
        [303,{'Location'=>'/man/'},[]]
      else
        man = man.chomp
        roff = man.R
        dir = R['//' + e.host + roff.dirname.sub(/.*\/share/,'')]
        res = dir.child roff.bare
        doc = res + '.e'
        path = Pathname man

        cached = path.exist? && doc.e && doc.m > path.stat.mtime
        if !cached
          uri = e.uri + '#'
          html = res + '.html'

          graph = {
            uri => {
              'uri' => uri,
              Title => name,
              Type => R[Purl+'ontology/bibo/Manual'],
              DC+'locale' => [],
              RDFs+'seeAlso' => [],
              SKOS+'related' => [],
              DC+'hasFormat' => [html]}}

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
          graph[uri][Content] = '<pre>'+CGI.escapeHTML(`#{pageCmd['utf8',"-t -P -u -P -b"]}`.utf8)+'</pre>'

          body = Nokogiri::HTML.parse(page).css('body')[0]
          body ||= Nokogiri::HTML.parse('<body><body>').css('body')[0]
          
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
          locales.push e.env['REQUEST_PATH'].R unless localesAvail.empty?
          (body.css('h1')[0] ||
           body.css('p')[0]).
            do{|top|
              top.add_previous_sibling H localesAvail.map{|l|
                locale = e.env['REQUEST_PATH']+'?lang='+l
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

        res.setEnv(e.env).response
      end
    end
  }

end
