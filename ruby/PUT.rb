#watch __FILE__

class R

  def PUT
    return [403,{},[]] if !allowWrite
    puts "PUT #{uri} #{@r['CONTENT_TYPE']}"
    @r.map{|k,v|puts k,v}
    inPUT
  end

  def inPUT
    ext = MIME.invert[@r['CONTENT_TYPE'].split(';')[0]].to_s # suffix from MIME
    return [406,{},[]] unless %q{gif html jpg json jsonld pdf png n3 ttl txt}.member? ext

    # container for states
    versions = docroot.child '.v'

    # identifier for current version
    doc = versions.child Time.now.iso8601.gsub(/\W/,'') + '.' + ext 

    body = @r['rack.input'].read
#    puts body
    doc.w body # create version

    cur = stripDoc.a('.' + ext)

    cur.delete if cur.e # unlink obsolete-version
    doc.ln_s cur        # link current

    [201,{
       'Location' => uri,
       'Access-Control-Allow-Origin' => @r['HTTP_ORIGIN'].do{|o|o.match(HTTP_URI) && o } || '*',
       'Access-Control-Allow-Credentials' => 'true',
    },[]]
  end

end
