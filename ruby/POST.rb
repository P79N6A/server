#watch __FILE__
class R

  def POST

    # POST handler at URI
    [@r['SERVER_NAME'],""].map{|h| justPath.cascade.map{|p|
        POST[h + p].do{|fn|fn[self,@r].do{|r| return r }}}}

    return [403,{},[]] if !allowWrite
    puts "POST #{uri} #{@r['CONTENT_TYPE']}"

    case @r['CONTENT_TYPE']
    when /^application\/x-www-form-urlencoded/
      formPOST
    else
      rdfPOST
    end
  end

  def formPOST
    params = (Rack::Request.new @r).params
    params.map{|k,v|
      s, p, t = JSON.parse CGI.unescape k rescue JSON::ParserError # triple (origin) URI
     (o = v.match(HTTP_URI) ? v.R : CleanHTML[v] # object URI or Literal
      t_ = s.R.predicatePath(p).objectPath(o)[0] # triple (current) URI
      t.R.delete if t && t != t_.to_s # delete obsolete triple
      s.R[p] = o unless o.class==String && o.empty?) if s&&p} # add triple
    snapshot
    [303,{'Location'=>uri+'?view=edit'+(params['mono'] ? '&mono' : '')},[]]
  end

  def rdfPOST
    inPUT
  end

end
