watch __FILE__
class R

  def PUT # non-destructive
    return [400,{},[]] unless @r['CONTENT_TYPE']
    return [403,{},[]] unless allowWrite
    ext = MIME.invert[@r['CONTENT_TYPE'].split(';')[0]].to_s # suffix from MIME
    return [406,{},[]] unless %w{gif html jpg json jsonld png n3 ttl}.member? ext

    # container for states
    versions = docroot.child '.v'

    # version URI
    doc = versions.child Time.now.iso8601.gsub(/\W/,'') + '.' + ext 
    body = @r['rack.input'].read
    doc.w body unless body.empty?

    main = stripDoc.a('.' + ext) # canonical doc-URI

    main.delete if main.e # unlink prior
    doc.ln main           # link current

    ldp
    [201,@r[:Response].update({Location: uri}),[]]
  rescue Exception => e
    puts e.class, e.message
    [400,{},[]]
  end

  def DELETE
    return [403, {}, ["Forbidden"]] unless allowWrite
    return [409, {}, ["resource not found"]] unless exist?
    puts "DELETE #{uri}"
    delete
    [200,{
       'Access-Control-Allow-Origin' => @r['HTTP_ORIGIN'].do{|o|o.match(HTTP_URI) && o } || '*',
       'Access-Control-Allow-Credentials' => 'true',
    },[]]
  end

  def delete; node.deleteNode if e; self end

  def appendFile line
    dir.mk
    File.open(pathPOSIX,'a'){|f|f.write line + "\n"}
  end

  def writeFile o,s=false
    dir.mk
    File.open(pathPOSIX,'w'){|f|
      f << (s ? o.to_json : o)}
    self
  rescue Exception => x
    puts caller[0..2],x
    self
  end
  alias_method :w, :writeFile

  def mkdir
    e || FileUtils.mkdir_p(pathPOSIX)
    self
  rescue Exception => x
    puts x
    self
  end
  alias_method :mk, :mkdir

  def ln t, y=:link
    t = t.R.stripSlash
    unless t.e || t.symlink?
      t.dir.mk
      FileUtils.send y, node, t.node
    end
  end

  def ln_s t; ln t, :symlink end

  def PATCH
    update
  end

  def POST
    return [403,{},[]] unless @r.signedIn && allowWrite
    mime = @r['CONTENT_TYPE']
    case mime
    when /^multipart\/form-data/
      filePOST
    when /^text\/(n3|turtle)/
      graphPOST
    when /^application\/sparql-update/
      update
    else
      [406,{'Accept-Post' => 'application/x-www-form-urlencoded, text/turtle, multipart/form-data'},[]]
    end
  end

  def filePOST
    p = (Rack::Request.new env).params
    if file = p['file']
      FileUtils.cp file[:tempfile], child(file[:filename]).pathPOSIX
      file[:tempfile].unlink
      ldp
      [201,@r[:Response].update({Location: uri}),[]]
    end
  end

  def graphPOST
    if @r.linkHeader['type'] == Container
      path = child(@r['HTTP_SLUG'] || rand.to_s.h[0..6]).setEnv(@r)
      path.PUT
      if path.e
        [200,@r[:Response].update({Location: path.uri}),[]]
      else
        mk
      end
    else
      self.PUT
    end
  end

  def update
    puts "PATCH #{uri}"
    query = @r['rack.input'].read
    puts query
    doc = ttl
    puts "doc #{doc}"
    model = RDF::Repository.new
    model.load doc.pathPOSIX, :base_uri => uri if doc.e
    sse = SPARQL.parse(query, update: true)
    sse.execute(model)
    doc.w model.dump(:ttl)
    ldp
    [200,@r[:Response],[]]
  end

end

class Pathname

  def deleteNode
    FileUtils.send (file?||symlink?) ? :rm : :rmdir, self
    parent.deleteNode if parent.c.empty? # parent now empty, delete it
  end

end
