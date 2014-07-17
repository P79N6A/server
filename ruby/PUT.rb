watch __FILE__

class R

  def PUT
    return [403,{},[]] if !allowWrite
    puts "PUT #{uri} #{@r['CONTENT_TYPE']}"
    inPUT
  end

  def inPUT
    ext = '.' + MIME.invert[@r['CONTENT_TYPE'].split(';')[0]].to_s # suffix from MIME

    versions = docroot.child '.v' # container for states

    # identifier for current version
    doc = versions.child Time.now.iso8601.gsub(/\W/,'') + ext 
    doc.w @r['rack.input'].read # create version

    cur = stripDoc.a(ext) # resource URI

    cur.delete if cur.e # wipe obsolete target
    doc.ln_s cur        # link current
    [201,{
       'Location' => uri,
       'Access-Control-Allow-Origin' => @r['HTTP_ORIGIN'].do{|o|o.match(HTTP_URI) && o } || '*',
       'Access-Control-Allow-Credentials' => 'true',
    },[]]
  end

  def MKCOL

  end

end
