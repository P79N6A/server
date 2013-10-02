watch __FILE__
class E

  def POST
    r = Rack::Request.new @r
    p = nil
    r.params.map{|k,v|
      s,p,o = (CGI.unescape k).split(S).map &:unpath; p = p.uri[0..-2].E
      puts "POST  s #{s} p #{p} o #{o.class} #{o} v #{v.class} #{v}"
      s[p] = v
    }
    @r.q.update({
                  'view' => 'editPO',
                  'graph' => 'editable',
                  'p' => p.uri,
                  'nocache' => 'true', 
                })
    self.GET
  rescue Exception => x
    Fn 'backtrace',x,@r
  end

end
