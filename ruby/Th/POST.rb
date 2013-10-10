watch __FILE__
class E

  def POST
    r = Rack::Request.new @r
    p = nil
    # each triple
    r.params.map{|k,v|

      # path-format triple
      sP,pP,oP = (CGI.unescape k).split S

      # original triple
      s,p,o = [sP,pP,oP].map &:unpath

      p = p.uri[0..-2].E if p.uri[-1] == '/'

      # object-delta URIs
      vU = E.literal v
      oU = oP.E

      # change detected
      unless oU.uri == vU.uri
        puts "#{o} -> v"
        # edit triple
        s[p] = vq
      end

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
