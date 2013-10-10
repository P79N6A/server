watch __FILE__
class E

  def POST
    r = Rack::Request.new @r
    p = nil
    r.params.map{|k,v|

      # path-ized Triple components
      sP,pP,oP = (CGI.unescape k).split S
      # original triple
      s,p,o = [sP,pP,oP].map{|c|c.unpath true}
      p = p.uri[0..-2].E if p.uri[-1] == '/'
      
      puts "s.#{s} p.#{p} :"
      puts "object  #{oP} #{o}"
      puts "objectV #{v}"

      # edit triple
      s[p] = v

      
    }

    # parameters for editor
    @r.q.update({ 'view' => 'editPO',
                  'graph' => 'editable',
                  'p' => p.uri,
                  'nocache' => 'true'})
    self.GET
  rescue Exception => x
    Fn 'backtrace',x,@r
  end

end
