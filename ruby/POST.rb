watch __FILE__
class E

  def POST
    case @r['CONTENT_TYPE']
    when /^application\/x-www-form-urlencoded/
      changed = false
      (Rack::Request.new @r).params.map{|k,v| s, p, tripleA = JSON.parse CGI.unescape k
        s = s.E
       pp = s.predicatePath p
        o = v.match(/\A(\/|http)[\S]+\Z/) ? v.E : F['cleanHTML'][v]
        tripleB = pp.objectPath(o)[0]
        if tripleA.to_s != tripleB.to_s
          tripleA && tripleA.E.do{|t| t.delete if t.e }
          s[p] = o unless o.class==String && o.empty?
          changed = true
        end}
      if changed
        g = {}
        fromStream g, :triplrDoc
        if g.empty? # no triples left
          ef.delete
        else        # snapshot to graph-doc
          ef.w g, true
        end
      end
    end
    [303,{'Location'=>uri+'?graph=edit'},[]]
#    self.GET
  end

end
