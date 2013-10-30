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
      mp = `man -w #{s} #{Shellwords.escape m}`.chomp
      unless mp.empty?

        # cache HTML renderings
        html = "/man/#{m}#{s}.html".E
        unless html.e && html.m > Pathname(mp).stat.mtime

          # create page
          page = `zcat #{mp} | groff -T html -man -P -D -P /dev/null`
          page = Nokogiri::HTML.parse page

          # add links
          body = page.css('body')[0]
          body.add_child H H.css('/css/man')
          body.add_child H[{_: :style, c: "a {background-color:#{E.cs}}"}]
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
