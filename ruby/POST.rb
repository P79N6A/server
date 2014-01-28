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
          s, p, o = [s, p, o].map &:unpath
          if s.uri.match(/^http/) && p.uri.match(/^http/)
            oO = v.match(/\A(\/|http)[\S]+\Z/) ? v.E : F['cleanHTML'][v]
            if o != oO
              changed = true
              s[p,o,oO]
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
    [303,{'Location'=>uri+'?graph=edit'},[]]
  end

end
