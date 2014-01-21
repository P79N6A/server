#watch __FILE__
class E
  
  fn '/man/GET',->e,r{
    manPath = '/usr/share/man'

    # eat selector
    name = e.pathSegment.uri.sub('/man/','/').tail

    # section requested?
    section = nil
    name.match(/^([0-9])(\/|$)/).do{|p|
      section = p[1]
      name = p.post_match }

    if !name || name.empty? || name.match(/\//)
      if section
        # enumerate section children
     body = H [H.css('/css/man'),{_: :style, c: "a {background-color: #{E.cs}}"},
            Pathname(manPath+'/man'+section).c.map{|p|
              n = p.basename.to_s.sub /\.[0-9][a-z]*\...$/,''
            }.group_by{|e|e[0].match(/[a-zA-Z]/) ? e[0].downcase : '0-9'}.sort.map{|g,m|
              [{_: :h3, c: g},
               m.map{|n|[{_: :a, href: '/man/'+section+'/'+n, c: n },' ']}]}]
        [200, {'Content-Type'=>'text/html; charset=utf-8'}, [body]]
      else
        e.response
      end
    else
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

        if !cached

          locales = Pathname(manPath).c.select{|p|p.basename.to_s.do{|b| !b.match(/^man/) && !b.match(/\./) }}.map{|p|File.basename p}
          localesAvail = locales.select{|l|
            File.exist? manPath + '/' + l + '/' + roff.uri.split('/')[-2..-1].join('/')}

          imagePath = htmlBase.d + '/images'
          FileUtils.mkdir_p imagePath unless File.exist? imagePath

          preconv = %w{hu pt tr}.member?(superLang) ? "" : "-k"
          pageCmd = "zcat #{man} | groff #{preconv} -T html -man -P -D -P #{imagePath}"
          page = `#{pageCmd}`#.to_utf8
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
            p = (i.attr 'src').unpathFs
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
        html.env(r).getFile
      end
    end
  }

end
