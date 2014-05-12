#watch __FILE__
class R

  GET['/man'] = -> e,r {
    graph = RDF::Graph.new
    manPath = '/usr/share/man'
    name = e.justPath.uri.sub(/^\/man/,'').tail || ''
    section = nil
    name.match(/^([0-9])(\/|$)/).do{|p| # optional section
      section = p[1]
      name = p.post_match}
    pageName = -> path {
      path.basename.to_s.sub /\.[0-9][a-z]*\...$/, '' }

    if name.empty? # top-level index
      if section # section index
        Pathname(manPath+'/man'+section).c.map{|p|
         name = pageName[p]
         graph << RDF::Statement.new(R['#'+name[0].downcase], R[LDP+'contains'], R['/man/'+section+'/'+name])}
      else # index pointers
        ('a'..'z').map{|a| graph << RDF::Statement.new('#'.R, R[LDP+'contains'], R['//'+r['SERVER_NAME']+'/man/'+a+'/'])}
      end
      r.graphResponse graph
    elsif alpha = name.match(/^([a-z])\/$/).do{|a|a[1]} # alpha index
      Pathname.glob(manPath+'/man*/'+alpha+'*').map{|a| graph << RDF::Statement.new('#'.R, R[LDP+'contains'], R['/man/' + pageName[a]])}
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
        htmlBase = R['//' + r['SERVER_NAME'] + roff.dirname.sub(/.*\/share/,'')]
        html = htmlBase.child roff.bare + '.html'
        cached = html.e && html.m > (Pathname man).stat.mtime
        if !cached
          locales = Pathname(manPath).c.select{|p|p.basename.to_s.do{|b| !b.match(/^man/) && !b.match(/\./) }}.map{|p|File.basename p}
          localesAvail = locales.select{|l|
            File.exist? manPath + '/' + l + '/' + roff.uri.split('/')[-2..-1].join('/')}

          imagePath = htmlBase.d + '/images'
          FileUtils.mkdir_p imagePath unless File.exist? imagePath

          preconv = %w{hu pt tr}.member?(superLang) ? "" : "-k"
          pageCmd = "zcat #{man} | groff #{preconv} -T html -man -P -D -P #{imagePath}"
#          puts [name,section,acceptLang,lang,superLang,langSH,roff,htmlBase,html,pageCmd]
          page = `#{pageCmd}`#.to_utf8
          page = Nokogiri::HTML.parse page
          body = page.css('body')[0]
          
          # add CSS link
          body.add_child H H.css('/css/man')
          body.add_child H[{_: :style, c: "a {background-color:#{R.cs}}"}]
          
          # add localization links
          (body.css('h1')[0] ||
           body.css('p')[0]
           ).add_previous_sibling H localesAvail.map{|l|
            {_: :a, class: :lang, href: r['REQUEST_PATH']+'?lang='+l, c: l}}
          
          # webize image paths
          body.css('img').map{|i|
            p = R.unPOSIX i.attr 'src'
            i.replace H[{_: :img, src: p}]}

          # inspect plaintext
          #  HTMLize hyperlinks
          #  markup commands
          body.xpath('//text()').map{|a|
            a.replace a.to_s.gsub('&gt;','>').hrefs.gsub /\b([^<>\s(]+)\(/mi, '<b>\1</b>('}
          body.css('font').map{|f|f.remove_attribute 'color'}

          qs = r['QUERY_STRING'].do{|q| q.empty? ? '' : '?' + q}
          # href-ize commands
          body.css('b').map{|b|
            b.next.do{|n|
              n.to_s.match(/\(([0-9])\)(.*)/).do{|section|
                name, s = b.inner_text, section[1]
                n.replace section[2]
                b.replace " <a href='/man/#{s}/#{name}#{qs}'><b>#{name}</b>(#{s})</a>"}}}

          html.w page
        end
        
        # response
        html.setEnv(r).fileGET
      end
    end
  }

  #  GET['/man'] = Man

end
