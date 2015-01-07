#watch __FILE__
class R

  def POST
    return [403,{},[]] if !allowWrite
    @r[:container] = true if directory?

    [@r['SERVER_NAME'],""].map{|h| justPath.cascade.map{|p| # bespoke handler
        POST[h + p].do{|fn|fn[self,@r].do{|r| return r }}}}

    case @r['CONTENT_TYPE']
    when /^application\/x-www-form-urlencoded/
      formPOST
    when /^multipart\/form-data/
      filePOST
    when /^text\/(n3|turtle)/
      dataPOST

    else
      [406,{'Accept-Post' => 'application/x-www-form-urlencoded, text/turtle, text/n3, multipart/form-data'},[]]
    end
  end

  def dataPOST
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

  def filePOST
    p = (Rack::Request.new env).params
    if file = p['file']
      FileUtils.cp file[:tempfile], child(file[:filename]).pathPOSIX
      file[:tempfile].unlink # free tmpfile
      ldp
      [201,@r[:Response].update({Location: uri}),[]]
    end
  rescue
    [400,{},[]]
  end

  def formPOST
    form = Rack::Request.new(@r).params
    return [400,{},['fragment field missing']] unless form['fragment']
    t = form[Title]
    slug = t && !t.empty? && t.slugify || rand.to_s.h[0..7]
    loc = @r[:container] ? (uri.t + Time.now.iso8601.gsub('-','/')+'/'+slug) : uri
    s = loc + '#' + form['fragment'].slugify # subject URI
    graph = {s => {'uri' => s}}              # graph
    form.keys.-(['fragment']).map{|p|        # form-data to graph
      o = form[p]
      o = if o.match HTTP_URI
            o.R
          elsif p == Content
            StripHTML[o]
          else
            o
          end
      graph[s][p] ||= []
      graph[s][p].push o unless o.class==String && o.empty?}
    ts = Time.now.iso8601.gsub /[-+:T]/, '' # timestamp
    path = s.R.fragmentPath      # storage path
    doc = path + '/' + ts + '.e' # storage URI
    doc.w graph, true            # write
    cur = path.a '.e'            # canonical URI
    cur.delete if cur.e          # unlink obsolete
    doc.ln cur                   # link current
    buildDoc                     # update containing-doc
    [303,{'Location' => loc},[]]
  end

end
