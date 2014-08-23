watch __FILE__

class R

  def PUT
    return [403,{},[]] if !allowWrite
    puts "PUT #{uri} #{@r['CONTENT_TYPE']}"
    @r.map{|k,v|puts k,v}
#    putDoc
  end

  def putDoc
    ext = MIME.invert[@r['CONTENT_TYPE'].split(';')[0]].to_s # suffix from MIME
    return [406,{},[]] unless %w{gif html jpg json jsonld png n3 ttl}.member? ext

    # container for states
    versions = docroot.child '.v'

    # identifier for current version
    doc = versions.child Time.now.iso8601.gsub(/\W/,'') + '.' + ext 

    # store version
    doc.w @r['rack.input'].read

    main = stripDoc.a('.' + ext)

    main.delete if main.e # unlink prior
    doc.ln_s main         # link current

    [201,{
       'Location' => uri,
       'Access-Control-Allow-Origin' => @r['HTTP_ORIGIN'].do{|o|o.match(HTTP_URI) && o } || '*',
       'Access-Control-Allow-Credentials' => 'true',
    },[]]
  end

end
