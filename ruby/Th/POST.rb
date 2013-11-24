watch __FILE__
class E

  def POST
    (Rack::Request.new @r).params.map{|k,v|
      s, p, o = (CGI.unescape k).split S
      if (s && p && o)
        oP = o # object path
        s,p,o = [s,p,o].map &:unpath
        s = s.uri[0..-2].E if s.uri[-1] == '/'
        p = p.uri[0..-2].E if p.uri[-1] == '/'
        unless oP.E == (E.literal v)
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
