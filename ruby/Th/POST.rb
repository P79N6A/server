watch __FILE__
class E

  def POST
    r = Rack::Request.new @r
    r.params.map{|k,v|
      s,p,o = CGI.unescape(k).split(S).map(&:unpath)
      puts :s,s,:p,p,:o,o
    }
    @r.q['view'] = 'editPO'
    @r.q['graph'] = 'editable'
    self.GET
  rescue Exception => x
    Fn 'backtrace',x,@r
  end

end
