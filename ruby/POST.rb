#watch __FILE__
class R

  def POST
    lambdas = pathSegment.cascade
    ['http://'+@r['SERVER_NAME'],""].map{|h| lambdas.map{|p|
        POST[h + p].do{|fn|fn[self,@r].do{|r| return r }}}}
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
      # original triple in this field
      s, p, o = JSON.parse CGI.unescape k rescue JSON::ParserError

      if s # parse successful?
        s = s.R # subject URI
        pp = s.predicatePath p # subject+predicate URI
        object = v.match(/\A(\/|http)[\S]+\Z/) ? v.R : CleanHTML[v] # object Literal | URI
        o_ = pp.objectPath(object)[0]
        if o.to_s != o_.to_s # changed?
          o && o.R.do{|t| t.delete if t.e } # -triple
          s[p] = object unless object.class==String && object.empty? # +triple
          changed = true
        end
      end}
    snapshot if changed # new doc
    [303,{'Location'=>uri+'?view=edit'+(params['mono'] ? '&mono' : '')},[]]
  end

end
