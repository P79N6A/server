#watch __FILE__

class R

  def PUT
    return [403,{},[]] if !allowWrite
    puts "PUT #{uri} #{@r['CONTENT_TYPE']}"
    if @r.linkHeader['type'] == LDP+'BasicContainer'
      self.MKCOL
    else
      putDoc
    end
  end

  def MKCOL
    return [403, {}, ["Forbidden"]]        unless allowWrite
    return [409, {}, ["parent not found"]] unless dir.exist?
    return [405, {}, ["file exists"]]      if file?
    return [405, {}, ["dir exists"]]       if directory?
    mk
    [200,{
       'Access-Control-Allow-Origin' => @r['HTTP_ORIGIN'].do{|o|o.match(HTTP_URI) && o } || '*',
       'Access-Control-Allow-Credentials' => 'true',
    },[]]
  end

  def mk
    e || FileUtils.mkdir_p(pathPOSIX)
    self
  rescue Exception => x
    puts x
    self
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

    main = stripDoc.a('.' + ext) # always the current doc

    main.delete if main.e # unlink prior
    doc.ln_s main         # link current

    [201,{
       'Location' => uri,
       'Access-Control-Allow-Origin' => @r['HTTP_ORIGIN'].do{|o|o.match(HTTP_URI) && o } || '*',
       'Access-Control-Allow-Credentials' => 'true',
    },[]]
  end

end
