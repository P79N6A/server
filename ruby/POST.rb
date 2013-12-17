watch __FILE__
class E

  def POST
    (Rack::Request.new @r).params.map{|k,v|
      s, p, o = (CGI.unescape k).split S
      if s && p && o
        oP = o # object path
        begin
          s,p,o = [s,p,o].map &:unpath
          s = s.uri[0..-2].E if s.uri[-1] == '/'
          p = p.uri[0..-2].E if p.uri[-1] == '/'
          unless oP.E == (E.literal v)
            puts ["POST",:s,uri,:p,p,:o,o,o.class,:oV,v,v.class].join ' '
            s[p,o,v] # edit
          end
        rescue  Exception => x
          puts x
        end
      end}

    # update graph snapshot
    g = {}
    fromStream g, :triplrFsStore
    ef.w g, true

    [303,{'Location'=>uri},[]]
  end

end
