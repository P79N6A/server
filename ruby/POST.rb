watch __FILE__
class R

  def POST
    # custom handler lookup
    pathSegment.do{|path|
      lambdas = path.cascade.map{|p| p.uri.t + 'POST' }
      ['http://'+@r['SERVER_NAME'],""].map{|h| lambdas.map{|p|
          F[h + p].do{|fn|fn[self,@r].do{|r| return r }}}}}

    case @r['CONTENT_TYPE']
    when /^application\/x-www-form-urlencoded/
      formPOST
    end
  end

  def formPOST
    changed = false
    (Rack::Request.new @r).params.map{|k,v|
      
      # triple ID field
      s, p, tripleA = JSON.parse CGI.unescape k
      s = s.R
      pp = s.predicatePath p

      # clean input 
      o = v.match(/\A(\/|http)[\S]+\Z/) ? v.R : F['cleanHTML'][v]

      # delta ID
      tripleB = pp.objectPath(o)[0]

      if tripleA.to_s != tripleB.to_s # changed?
        # remove triple
        tripleA && tripleA.R.do{|t| t.delete if t.e }
        # create triple
        s[p] = o unless o.class==String && o.empty?
        changed = true
      end}
    if changed # update doc
      g = {} # triples -> graph
      fromStream g, :triplrDoc
      if g.empty? # 0 triples
        ef.delete
      else # graph -> doc #TODO history: mint docURI for version and link to it
        ef.w g, true
      end
    end
    [303,{'Location'=>uri+'?graph=edit'},[]]
  end

end
