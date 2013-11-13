#watch __FILE__
class E
  
  fn '/man/GET',->e,r{
    name = e.pathSegment.uri.sub('/man/','/').tail
    section = nil
    name.match(/^([0-9])\/(.*)/).do{|p|
      section, name = p[1], p[2] }

    if name.empty? || name.match(/\//)
      e.response
    else

      manPath = '/usr/share/man'
      acceptLang = r['HTTP_ACCEPT_LANGUAGE'].do{|a|a.split(/,/)[0]}
      lang = r.q['lang'] || acceptLang
      superLang = lang.do{|l| (l.split /[_-]/)[0] }
      langSH = lang.do{|l| '-L ' + l.sub('-','_').sh }
      man = `man #{langSH} -w #{section} #{name.sh}`.chomp      

      if man.empty?
        return false
      else

        roff = man.E
        htmlBase = roff.dir.to_s.sub(/.*\/share/,'').E
        html = htmlBase.as roff.bare + '.html'
        cached = html.e && html.m > (Pathname man).stat.mtime
#        cached=false

        if !cached

          locales = Pathname(manPath).c.select{|p|p.basename.to_s.do{|b| !b.match(/^man/) && !b.match(/\./) }}.map{|p|File.basename p}
          localesAvail = locales.select{|l|
            File.exist? manPath + '/' + l + '/' + roff.uri.split('/')[-2..-1].join('/')}

          imagePath = htmlBase.d + '/images'
          FileUtils.mkdir_p imagePath unless File.exist? imagePath

          preconv = %w{hu pt tr}.member?(superLang) ? "" : "-k"
          pageCmd = "zcat #{man} | groff #{preconv} -T html -man -P -D -P #{imagePath}"
          page = `#{pageCmd}`#.to_utf8

          [[:name,name],[:acceptLang,acceptLang],[:lang, lang],[:langSH, langSH],[:superLang, superLang],[:roff,man],[:htmlBase,htmlBase.d],[:imagePath,imagePath],[:localizations,localesAvail],[:pageCmd,pageCmd]].map{|p| puts [" "*(13-p[0].size),*p].join ' '}
          
          page = Nokogiri::HTML.parse page
          body = page.css('body')[0]
          
          # add CSS link
          body.add_child H H.css('/css/man')
          body.add_child H[{_: :style, c: "a {background-color:#{E.cs}}"}]
          
          # add localization links
          (body.css('h1')[0] ||
           body.css('p')[0]
           ).add_previous_sibling H localesAvail.map{|l|
            {_: :a, class: :lang, href: r['REQUEST_PATH']+'?lang='+l, c: l}}
          
          # webize image paths
          body.css('img').map{|i|
            p = (i.attr 'src').unpathURI
            i.replace H[{_: :img, src: p}]}

          # inspect plaintext
          #  HTMLize hyperlinks
          #  markup commands
          body.xpath('//text()').map{|a|
            a.replace a.to_s.gsub('&gt;','>').hrefs.gsub /\b([^<>\s(]+)\(/mi, '<b>\1</b>('
          }
          
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
        html.env(r).getFile
      end
    end
  }

end
