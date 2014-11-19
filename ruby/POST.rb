watch __FILE__
class R

  def POST
    return [403,{},[]] if !allowWrite
    @r[:container] = true if directory?

    # bespoke handler
    [@r['SERVER_NAME'],""].map{|h| justPath.cascade.map{|p|
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
    if @r.linkHeader['type'] == LDP+'BasicContainer' # create container
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
    frag = form['fragment'].slugify

    if @r[:container] # POST to container - mint contained-resource URI
      prefix = Time.now.iso8601.sub('-','/')
      slug = if form[Title] && !form[Title].empty?
               form[Title].slugify
             else
               rand.to_s.h[0..7]
             end
      s = uri + prefix + '/' + slug
    else
      s = uri + '#' + frag
    end
    r = s.R
    graph = {s => {'uri' => s}}

    # form data to graph
    form.keys.-(['fragment']).map{|p|
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

    ts = Time.now.iso8601.sub('-','.').sub('-','/').gsub /[+:T]/, '' # timestamp
    fragPath = r.fragmentPath            # frag-storage container
    fragDoc = fragPath + '/' + ts + '.e' # frag-storage URI
    fragDoc.w graph, true # store fragment
    cur = fragPath.a '.e' # canonical frag-URI
    cur.delete if cur.e   # unlink obsolete version
    fragDoc.ln cur        # link current version

    buildDoc

    [303,{'Location'=>uri+'?edit'},[]]
  end

end
