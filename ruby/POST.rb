watch __FILE__
class E

  def POST
    type = @r['CONTENT_TYPE']
    case type
    when /^application\/sparql-update/
      puts "SPARQL"
    when /^application\/x-www-form-urlencoded/
      changed = false
      (Rack::Request.new @r).params.map{|k,v|
        s, p, o = (CGI.unescape k).split /\/\._/
        if s && p && o 
          oP = o # original object URI (maybe expands to literal below)
          s, p, o = [s, p, o].map &:unpath
          if s.uri.match(/^http/) && p.uri.match(/^http/)
            puts "POST <#{s}> <#{p}> <#{oP}> <#{E.literal v}>"
            if oP.E != (E.literal v) 
              changed = true
              s[p,o,v]
            end
          end
        end}
      if changed
        g = {}
        fromStream g, :triplrFsStore
        ef.w g, true
      end
    end
    self.GET
    #[303,{'Location'=>uri},[]]    
  end

end
