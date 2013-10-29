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
        s = p[1]; m = p[2]}
      # source
      mp = `man -w #{s} #{Shellwords.escape m}`.chomp
      unless mp.empty?
        # cache HTML renderings
        html = "/man/#{m}#{s}.html".E
        unless html.e && html.m > Pathname(mp).stat.mtime
          html.w `zcat #{mp} | groff -T html -man`
        end
        html.env(r).GET_file
      end
    } || F[E404][e,r]}

end
