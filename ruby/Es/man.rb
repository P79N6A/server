watch __FILE__
class E
  
  def triplrMan
    if size < 256e3
      yield uri, Content, `zcat #{sh} | groff -T html -man`
    end
  end
  
  fn '/man/GET',->e,r{
    e.pathSegment.uri.sub('/man/','/').tail.do{|m|

      # section selection
      s = nil
      m.match(/^([0-9])\/(.*)/).do{|p|
        s, m = p[1], p[2] }
      
      locale = r.q['lang'] || r['HTTP_ACCEPT_LANGUAGE'].do{|a| a.split(/,/)[0] }
      localization = locale.do{|l| '-L ' + l }
      lang = locale.do{|l| "?lang=" + l }
      
      # source
      puts "man #{localization} -w #{s} #{Shellwords.escape m}"
      man = `man #{localization} -w #{s} #{Shellwords.escape m}`.chomp
      unless man.empty?

        roff = man.E
        html = (roff.dir.to_s.sub(/.*\/share/,'') + '/' + roff.bare + '.html').E

        cached = html.e && html.m > (Pathname man).stat.mtime
        cached = false
        unless cached
          puts " #{man} -> #{html}"

          locales = Pathname('/usr/share/man').c.select{|p|p.basename.to_s.do{|b| !b.match(/^man/) && !b.match(/\./) }}.map{|p|File.basename p}

          # basic HTML from groff
          page = `zcat #{man} | groff -T html -man -P -D -P /dev/null`.to_utf8
          page = Nokogiri::HTML.parse page
          body = page.css('body')[0]
          
          # add CSS link
          body.add_child H H.css('/css/man')
          body.add_child H[{_: :style, c: "a {background-color:#{E.cs}}"}]
          
          # add localization links
          (body.css('h1')[0] ||
           body.css('p')[0]
           ).add_previous_sibling H locales.map{|l|
            {_: :a, class: :lang, href: r['REQUEST_PATH']+'?lang='+l, c: l}}
          
          # markup commands in SEE ALSO
          page.css('a[name="SEE ALSO"]')[0].do{|a|
            also = a.parent.next_element
            also.inner_html = also.text.gsub /\b([^<>\s(]+)\(/mi, '<b>\1</b>('}
          
          # href-ize commands
          page.css('b').map{|b|
            b.next.do{|n|
              n.to_s.match(/\(([0-9])\)(.*)/).do{|section|
                name, s = b.inner_text, section[1]
                n.replace section[2]
                b.replace " <a href='/man/#{s}/#{name}#{lang}'><b>#{name}</b>(#{s})</a>"}}}

          html.w page
        end
          
        # response
        html.env(r).GET_file
      end
    } || F[E404][e,r]}

end
