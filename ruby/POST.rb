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
            oQ = v.match(/\A(\/|http)[\S]+\Z/) ? v.E : E.literal(v)
            puts "POST <#{s}> <#{p}> <#{oP}> <#{oQ}>"
            if oP.E != oQ
              changed = true
              s[p,o,oQ]
            end
          end
        end}
      if changed
        g = {}
        fromStream g, :triplrDoc
        if g.empty?
          ef.deleteNode
        else
          ef.w g, true
        end
      end
    end
    [303,{'Location'=>uri},[]]
  end

end
