#watch __FILE__
class R

  Man = -> e,r {
    graph = RDF::Graph.new
    uri = R['//'+r['SERVER_NAME']+r['REQUEST_URI']]
    manPath = '/usr/share/man'
    name = e.justPath.stripSlash.uri.sub(/^\/man/,'').tail || ''
    section = nil
    name.match(/^([0-9])(\/|$)/).do{|p| # optional section
      section = p[1]
      name = p.post_match}

    if name.empty?
      E404[e,r]
    else

      acceptLang = r['HTTP_ACCEPT_LANGUAGE'].do{|a|a.split(/,/)[0]}
      lang = r.q['lang'] || acceptLang
      superLang = lang.do{|l| (l.split /[_-]/)[0] }
      langSH = lang.do{|l| '-L ' + l.sub('-','_').sh }

      findman = "man #{langSH} -w #{section} #{name.sh}"
      man = `#{findman}`.chomp      

      if man.empty?
        E404[e,r]
      else

        roff = man.R
        R['//' + r['SERVER_NAME'] + '/' + name[0].downcase +  c]
        dir = R['//' + r['SERVER_NAME'] + roff.dirname.sub(/.*\/share/,'')]
        res = dir.child roff.bare
        doc = res + '.e'
        cached = doc.e && doc.m > (Pathname man).stat.mtime

        if !cached
          uri = e.uri + '#'
          txt = res + '.txt'
          html = res + '.html'

          graph = {
            uri => {
              'uri' => uri,
              Title => name,
              Type => R[Purl+'ontology/bibo/Manual'],
              DC+'language' => lang,
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

          pageCmd = -> format,opts="" {"#{gzipped ? 'z' : ''}cat #{man} | groff #{preconv} -T #{format} -mandoc #{opts}"}

          page = `#{pageCmd['html',"-P -D -P #{imagePath}"]}`.to_utf8
          `#{pageCmd['utf8',"-t -P -u -P -b"]} > #{txt.sh}`

          body = Nokogiri::HTML.parse(page).css('body')[0]
          
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
                link = linkPath.R.setEnv(r).bindHost
                graph[uri][SKOS+'related'].push link
                b.replace " <a href='#{linkPath}'><b>#{name}</b>(#{s})</a>"}}}

          html.w body.children.to_xhtml
          doc.w graph, true
        end

        res.setEnv(r).response
      end
    end
  }

end
