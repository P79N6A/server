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
        s, p, tripleA = JSON.parse CGI.unescape k
        o = v.match(/\A(\/|http)[\S]+\Z/) ? v.E : F['cleanHTML'][v]
        pp = s.E.predicatePath(p)
        tripleB = pp.objectPath o
        puts "A #{tripleA}"
        puts "B #{tripleB}"
        if tripleA != tripleB
          changed = true
          puts "Edit"
#          s[p,o,oO]
        end
      }
      
      if changed
        g = {}
        fromStream g, :triplrDoc
        if g.empty?
#          ef.deleteNode
        else
          ef.w g, true
        end
      end
    end
#    [303,{'Location'=>uri+'?graph=edit'},[]]
    self.GET
  end

end
