watch __FILE__
class R
  def PUT
    etag = @r['HTTP_IF_MATCH']
    puts "PUT #{uri}"
    puts "  e #{etag}"
    puts "cur #{response[1]['ETag']}"
#    return [412,{},[]] if etag && ()
    mime = @r['CONTENT_TYPE'].split(';')[0]
    ext = '.' + MIME.invert[mime].to_s
    versions = docroot.child('.v')
    doc = versions.child Time.now.iso8601.gsub(/\W/,'') + ext 
    doc.w @r['rack.input'].read
    cur = stripDoc.a(ext)
    FileUtils.mv cur.pathPOSIX, versions.child('0'+ext).pathPOSIX if cur.node.file? && !cur.node.symlink?
    cur.delete if cur.e
    doc.ln_s cur
    [201,{ 'Location' => uri},[]]
  end
end
