#watch __FILE__
class R

  def POST

    # POST handler at URI
    [@r['SERVER_NAME'],""].map{|h| justPath.cascade.map{|p|
        POST[h + p].do{|fn|fn[self,@r].do{|r| return r }}}}

    case @r['CONTENT_TYPE']
    when /^application\/x-www-form-urlencoded/
      formPOST
    else
      rdfPOST
    end
  end

  def formPOST
    changed = false
    params = (Rack::Request.new @r).params
    params.map{|k,v|
      s, p, o = JSON.parse CGI.unescape k rescue JSON::ParserError
      if s
        s = s.R # subject URI
        pp = s.predicatePath p # subject+predicate URI
        object = v.match(HTTP_URI) ? v.R : CleanHTML[v] # object Literal | URI
        o_ = pp.objectPath(object)[0]
        if o.to_s != o_.to_s # changed?
          puts "edit #{o} -> #{o_}"
          o && o.R.do{|t| t.delete if t.e } # -triple
          s[p] = object unless object.class==String && object.empty? # +triple
          changed = true
        end
      end}
    snapshot if changed # new doc
    [303,{'Location'=>uri+'?view=edit'+(params['mono'] ? '&mono' : '')},[]]
  end

  def rdfPOST
    return [403,{},[]] if !allowWrite
    puts "POST #{uri} #{@r['CONTENT_TYPE']}"
    inPUT
  end

end
