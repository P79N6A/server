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

      # source
      man = `man -w #{s} #{Shellwords.escape m}`.chomp
      unless man.empty?

        roff = man.E
        html = (roff.dir.to_s.sub(/.*\/share/,'') + '/' + roff.bare + '.html').E

        unless html.e && html.m > Pathname(man).stat.mtime
          puts "updating"
          langs = Pathname('/usr/share/man').c.select{|p|!p.to_s.match /man[^\/]+$/}.map{|p|File.basename p}
          puts "langs #{langs}"
          # create page
          page = `zcat #{man} | groff -T html -man -P -D -P /dev/null`
          page = Nokogiri::HTML.parse page
          body = page.css('body')[0]
          
          # CSS
          body.add_child H H.css('/css/man')
          body.add_child H[{_: :style, c: "a {background-color:#{E.cs}}"}]
          
          # markup plaintext commands in SEE ALSO
          page.css('a[name="SEE ALSO"]')[0].do{|a|
            also = a.parent.next_element
            also.inner_html = also.text.gsub /\b([^<>\s(]+)\(/mi, '<b>\1</b>('}
          
          # commands to links
          page.css('b').map{|b|
            b.next.do{|n|
              n.to_s.match(/\(([0-9])\)(.*)/).do{|section|
                name, s = b.inner_text, section[1]
                n.replace section[2]
                b.replace " <a href='/man/#{s}/#{name}'><b>#{name}</b>(#{s})</a>"}}}

          html.w page
        end
          
        # response
        html.env(r).GET_file
      end
    } || F[E404][e,r]}

end
