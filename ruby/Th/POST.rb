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
      puts [:POST,:s,s,:p,p,:o,o.class,o].join(' ')

      # nuke trailing slash(es)
      s = s.uri[0..-2].E if s.uri[-1] == '/'
      p = p.uri[0..-2].E if p.uri[-1] == '/'

      # object-delta URIs
      vU = E.literal v
      oU = oP.E

      # change detected?
      unless oU.uri == vU.uri
        # edit triple
        s[p,o,v]
      end

      # snapshot current resource state
      
    }
    @r.q.update({'view' => 'editPO',
                 'graph' => 'editable'})
    self.GET
  end

end
