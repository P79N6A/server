#watch __FILE__
class R

  def POST
    pathSegment.do{|path| # handler cascade
      lambdas = path.cascade.map{|p| p.uri.t + 'POST' }
      ['http://'+@r['SERVER_NAME'],""].map{|h| lambdas.map{|p|
          F[h + p].do{|fn|fn[self,@r].do{|r| return r }}}}}

    case @r['CONTENT_TYPE']
    when /^application\/x-www-form-urlencoded/
      formPOST
    end
  end

  def snapshot
    g = {} # graph
    fromStream g, :triplrDoc
    if g.empty? # 0 triples
      jsonDoc.delete
    else # graph -> doc
      jsonDoc.w g, true
    end
  end

  def formPOST
    changed = false
    params = (Rack::Request.new @r).params
    params.map{|k,v|
      s, p, tripleX = JSON.parse CGI.unescape k rescue JSON::ParserError
      if s # parse successful?
        s = s.R # subject URI
        pp = s.predicatePath p # s+p path
        o = v.match(/\A(\/|http)[\S]+\Z/) ? v.R : F['cleanHTML'][v] # HTML cleanup
        tripleY = pp.objectPath(o)[0]   # editable triple
        if tripleX.to_s != tripleY.to_s # changed?
          tripleX && tripleX.R.do{|t| t.delete if t.e } # remove triple
          s[p] = o unless o.class==String && o.empty?   # add triple
          changed = true
        end
      end}
    snapshot if changed # update collated doc
    [303,{'Location'=>uri+'?view=edit'+(params['mono'] ? '&mono' : '')},[]]
  end

end
