watch __FILE__
class E

  def POST
    r = Rack::Request.new @r
    p = nil
    r.params.map{|k,v|

      # path-ized Triple components
      sP,pP,oP = (CGI.unescape k).split S

      # original triple
      s,p,o = [sP,pP,oP].map &:unpath
      p = p.uri[0..-2].E if p.uri[-1] == '/'

      # object-delta URI
      vU = E.literal v
      oU = oP.E

      puts "s #{s} p #{p} #{o}"
      puts "object  #{oU} #{o}"
      puts "objectN #{vU} #{v}"

      puts "objects #{o == v ? "MATCH" : "dont match" }"
      puts "objIDs #{oU.uri == vU.uri ? "MATCH" : "dont match" }"

      # edit triple
      s[p] = v

      # snapshot current resource state
      
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
