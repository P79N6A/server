#watch __FILE__

class R

  def PUT
    return [403,{},[]] if !allowWrite
    puts "PUT #{uri} #{@r['CONTENT_TYPE']}"
    ext = '.' + MIME.invert[@r['CONTENT_TYPE'].split(';')[0]].to_s
    vs = docroot.child '.v'
    doc = vs.child Time.now.iso8601.gsub(/\W/,'') + ext 
    doc.w @r['rack.input'].read
    cur = stripDoc.a(ext)
    FileUtils.mv cur.pathPOSIX, vs.child('0'+ext).pathPOSIX if cur.node.file? && !cur.node.symlink?
    cur.delete if cur.e
    doc.ln_s cur
    [201,{
       'Location' => uri,
       'Access-Control-Allow-Origin' => @r['HTTP_ORIGIN'].do{|o|o.match(HTTP_URI) && o } || '*',
       'Access-Control-Allow-Credentials' => 'true',
    },[]]
  end

end
