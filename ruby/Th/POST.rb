watch __FILE__
class E

  def POST
    (Rack::Request.new @r).params.map{|k,v|
      s,p,o = (CGI.unescape k).split S
      if s&&p&&o
        oP = o
        s,p,o = [s,p,o].map &:unpath
        s = s.uri[0..-2].E if s.uri[-1] == '/'
        p = p.uri[0..-2].E if p.uri[-1] == '/'
        vU = E.literal v
        oU = oP.E
        unless oU.uri == vU.uri
          s[p,o,v] # edit
        end
      end}

    g={}
    fromStream g, :triplrFsStore
    ef.w g,true

    @r.q.update({'view' => 'editPO','graph' => 'editable'})
    self.GET
  end

end
