watch __FILE__
class R
  def PUT
    mime = @r['CONTENT_TYPE'].split(';')[0]
    ext = '.' + MIME.invert[mime].to_s
    doc = stripDoc.a ext 
    doc.w @r['rack.input'].read
    [201,{ 'Location' => uri},[]]
  end
end
