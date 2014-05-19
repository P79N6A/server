#watch __FILE__
class R

  # to mount man-handler on / (optionally with hostname)
  Man = -> e,r { # GET['host/'] = Man
    graph = RDF::Graph.new
    manPath = '/usr/share/man'
    name = e.justPath.uri.sub(/^\/man/,'').tail || ''
    section = nil
    name.match(/^([0-9])(\/|$)/).do{|p| # optional section
      section = p[1]
      name = p.post_match}
    pageName = -> path {
      path.basename.to_s.sub /\.[0-9][a-z]*\...$/, '' }

    if name.empty?

      if section # section-index
        Pathname(manPath+'/man'+section).c.map{|p|
         name = pageName[p]
         graph << RDF::Statement.new(R['#'+name[0].downcase], R[LDP+'contains'], R['/man/'+section+'/'+name])}
         graph << RDF::Statement.new(R['#'], R[SIOC+'has_container'], R['/man'])

      else # alpha-index pointers
        ('a'..'z').map{|a| graph << RDF::Statement.new('#'.R, R[LDP+'contains'], R['//'+r['SERVER_NAME']+'/man/'+a+'/'])}
      end
      r.graphResponse graph

      # alpha-index
    elsif alpha = name.match(/^([a-z])\/$/).do{|a|a[1]}
      Pathname.glob(manPath+'/man*/'+alpha+'*').map{|a| graph << RDF::Statement.new('#'.R, R[LDP+'contains'], R['/man/' + pageName[a]])}
      graph << RDF::Statement.new(R['#'], R[SIOC+'has_container'], R['/man'])
      r.graphResponse graph

    else # page

      acceptLang = r['HTTP_ACCEPT_LANGUAGE'].do{|a|a.split(/,/)[0]}
      lang = r.q['lang'] || acceptLang
      superLang = lang.do{|l| (l.split /[_-]/)[0] }
      langSH = lang.do{|l| '-L ' + l.sub('-','_').sh }
      man = `man #{langSH} -w #{section} #{name.sh}`.chomp      

      if man.empty?
        E404[e,r]
      else

        roff = man.R
        dir = R['//' + r['SERVER_NAME'] + roff.dirname.sub(/.*\/share/,'')]
        res = dir.child roff.bare
        doc = res + '.e'
        cached = doc.e && doc.m > (Pathname man).stat.mtime

        if !cached
          uri = e.uri + '#'
          graph = {
            uri => {
              'uri' => uri,
              Title => name,
              Type => R[Purl+'ontology/bibo/Manual'],
              DC+'language' => lang,
              DC+'locale' => [],
              RDFs+'seeAlso' => [],
              SIOC+'has_container' => [R['/man/'+name[0]+'/']],
            }}
          graph[uri][SIOC+'has_container'].push R['/man/'+section] if section
          locales = graph[uri][DC+'locale']
          also = graph[uri][RDFs+'seeAlso']

          localesAvail = Pathname(manPath).c.select{|p|p.basename.to_s.do{|b|!b.match(/^man/) && !b.match(/\./)}}.map{|p|File.basename p}.select{|l|
            File.exist? manPath + '/' + l + '/' + roff.uri.split('/')[-2..-1].join('/')}

          imagePath = dir.d + '/images'
          FileUtils.mkdir_p imagePath unless File.exist? imagePath

          preconv = %w{hu pt tr}.member?(superLang) ? "" : "-k"
          pageCmd = "zcat #{man} | groff #{preconv} -T html -man -P -D -P #{imagePath}"
          page = `#{pageCmd}`.to_utf8
          body = Nokogiri::HTML.parse(page).css('body')[0]
          
          # add CSS link
          body.add_child H H.css('/css/man')
          
          # webize image paths
          body.css('img').map{|i|
            p = R.unPOSIX i.attr 'src'
            i.replace H[{_: :img, src: p}]}
          body.css('font').map{|f|f.remove_attribute 'color'}

          body.xpath('//text()').map{|a| # HTMLize plain-text links       bare command-refs to HTML
            a.replace a.to_s.gsub('&amp;','&').gsub('&gt;','>').gsub('&lt;','<').hrefs.gsub /\b([^<>\s(]+)\(/mi, '<b>\1</b>('}

          body.css('a').map{|a| # inspect links
            a.attr('href').do{|href|
              also.push R[href] unless href.match(/^#/)}}

          # add localization links
          locales.push r['REQUEST_PATH'].R unless localesAvail.empty?
          (body.css('h1')[0] ||
           body.css('p')[0]
           ).add_previous_sibling H localesAvail.map{|l|
            locale = r['REQUEST_PATH']+'?lang='+l
            locales.push R[locale]
            {_: :a, class: :lang, href: locale, c: l}}

          # RDF + HTML command-refs
          qs = r['QUERY_STRING'].do{|q| q.empty? ? '' : '?' + q}
          body.css('b').map{|b|
            b.next.do{|n|
              n.to_s.match(/\(([0-9])\)(.*)/).do{|section|
                name, s = b.inner_text, section[1]
                n.replace section[2]
                linkPath = "/man/#{s}/#{name}#{qs}"
                link = linkPath.R.setEnv(r).bindHost
                also.push link
                b.replace " <a href='#{linkPath}'><b>#{name}</b>(#{s})</a>"}}}

          graph[uri][Content] = body.children.to_xhtml
          doc.w graph, true
        end

        res.R.setEnv(r).response
      end
    end
  }

  #  GET['/man'] = Man

end
