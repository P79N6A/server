watch __FILE__
class E
  
  def triplrMan
    if size < 256e3
      yield uri, Content, `zcat #{sh} | groff -T html -man`
    end
  end
  
  fn '/man/GET',->e,r{
    e.pathSegment.uri.sub('/man/','/').tail.do{|name|

      manPath = '/usr/share/man'
      acceptLang = r['HTTP_ACCEPT_LANGUAGE'].do{|a|a.split(/,/)[0]}
      lang = r.q['lang'] || acceptLang
      langSH = lang.do{|l| '-L ' + l.sub('-','_').sh }
      q = r['QUERY_STRING'].do{|q| q.empty? ? '' : '?' + q}
      
      section = nil
      name.match(/^([0-9])\/(.*)/).do{|p|
        section, name = p[1], p[2] }
      man = `man #{langSH} -w #{section} #{name.sh}`.chomp
      
      unless man.empty?

        roff = man.E
        htmlBase = roff.dir.to_s.sub(/.*\/share/,'').E
        html = htmlBase.as roff.bare + '.html'
        cached = html.e && html.m > (Pathname man).stat.mtime
        cached = false        
        unless cached
          locales = Pathname(manPath).c.select{|p|p.basename.to_s.do{|b| !b.match(/^man/) && !b.match(/\./) }}.map{|p|File.basename p}
          localesAvail = locales.select{|l|
            File.exist? manPath + '/' + l + '/' + roff.uri.split('/')[-2..-1].join('/')}
          imagePath = htmlBase.d + '/images'; FileUtils.mkdir_p imagePath unless File.exist? imagePath
          preconv = %w{hu pt tr}.member?(lang) ? "" : "-k"
          pageCmd = "zcat #{man} | groff #{preconv} -T html -man -P -D -P #{imagePath}"
          page = `#{pageCmd}`.to_utf8

        [[:acceptLang,acceptLang],
         [:lang, lang],
         [:langSH, langSH],
         [:qs, q],
         [:roff,man],
         [:htmlBase,htmlBase.d],
         [:imagePath,imagePath],
         [:localizations,localesAvail],
         [:pageCmd,pageCmd],
         [:cached?, cached ? :true : :false],
        ].map{|p|
          puts [" "*(13-p[0].size),*p].join ' '}
          
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
          
          # inspect plaintext
          #  HTMLize hyperlinks
          #  markup commands
          page.xpath('//text()').map{|a|
            a.replace a.to_s.gsub('&gt;','>').hrefs.gsub /\b([^<>\s(]+)\(/mi, '<b>\1</b>('
          }
          
          # href-ize commands
          page.css('b').map{|b|
            b.next.do{|n|
              n.to_s.match(/\(([0-9])\)(.*)/).do{|section|
                name, s = b.inner_text, section[1]
                n.replace section[2]
                b.replace " <a href='/man/#{s}/#{name}#{q}'><b>#{name}</b>(#{s})</a>"}}}

          html.w page
        end
          
        # response
        html.env(r).GET_file
      end
    } || F[E404][e,r]}

end
