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
          page = `zcat #{mp} | groff -T html -man -P -D -P /dev/null`
          page = Nokogiri::HTML.parse page
          page.css('a[name="SEE ALSO"]')[0].do{|a|
            also = a.parent.next_element
            also.inner_html = also.text.gsub /\b([^(]+)\(([0-9])\)/mi, '<a href="/man/\2/\1"><b>\1</b>(\2)</a>'}
          html.w page
        end
        
        # response
        html.env(r).GET_file
      end
    } || F[E404][e,r]}

end
