watch __FILE__
class E

  def POST
    r = Rack::Request.new @r
    r.params.map{|k,v|
      puts CGI.unescape(k).split(S).map &:unpath
    }
    [200]
  rescue Exception => x
    Fn 'backtrace',x,@r
  end

end
