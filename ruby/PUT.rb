#watch __FILE__
class R

  def PUT
    ext = MIME.invert[@r['CONTENT_TYPE'].split(';')[0]].to_s # suffix from MIME
    return [403,{},[]] if !allowWrite
    return [406,{},[]] unless %w{gif html jpg json jsonld png n3 ttl}.member? ext

    # container for states
    versions = docroot.child '.v'

    # identifier for current version
    doc = versions.child Time.now.iso8601.gsub(/\W/,'') + '.' + ext 

    # store version
    doc.w @r['rack.input'].read

    main = stripDoc.a('.' + ext) # canonical doc-URI

    main.delete if main.e # unlink prior
    doc.ln main           # link current

    ldp
    [201,@r[:Response].update({Location: uri}),[]]
  end

end
