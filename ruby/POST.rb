#watch __FILE__
class R

  def POST
    return [403,{},[]] unless @r.signedIn && allowWrite
    mime = @r['CONTENT_TYPE']
    case mime
    when /^multipart\/form-data/
      filePOST
    when /^text\/(n3|turtle)/
      graphPOST
    when /^application\/sparql-update/
      sparqlPOST
    else
      [406,{'Accept-Post' => 'application/x-www-form-urlencoded, text/turtle, text/n3, multipart/form-data'},[]]
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
        path.MKCOL
      end
    else
      self.PUT
    end
  end

  def sparqlPOST
    query = @r['rack.input'].read
    doc = ttl
    model = RDF::Repository.new
    model.load doc if doc.e
    puts "POST target #{uri}"
    puts "storage in #{doc}"
    puts "UPDATE"; puts query
    sse = SPARQL.parse(query, update: true)
    sse.execute(model)
    doc.w model.dump(:ttl)
    [200,{},[]]
  end

end
