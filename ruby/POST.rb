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
        s = s.E
        o = v.match(/\A(\/|http)[\S]+\Z/) ? v.E : F['cleanHTML'][v]
        pp = s.predicatePath(p)
        tripleB = pp.objectPath(o)[0]
        puts "A #{tripleA}"
        puts "B #{tripleB}"
        if tripleA != tripleB
          changed = true
          tripleA && tripleA.E.do{|t|
            t.delete if t.e }
          s[p] = o
        end
      }
      
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
#    self.GET
  end

end
