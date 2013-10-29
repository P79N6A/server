watch __FILE__
class E
  
  def triplrMan
    if size < 256e3
      yield uri, Content, `zcat #{sh} | groff -T html -man`
    end
  end

  fn '/man/GET',->e,r{
    e.pathSegment.uri.sub('/man/','/').tail.do{|m|
      m = Shellwords.escape m
      mp = `man -w #{m}`.chomp
      `zcat #{mp} | groff -T html -man`.hR
    } || F[E404][e,r]}

end
