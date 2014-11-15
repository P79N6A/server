#watch __FILE__
class R

  def POST

    # bespoke handler in path cascade
    [@r['SERVER_NAME'],""].map{|h| justPath.cascade.map{|p|
        POST[h + p].do{|fn|fn[self,@r].do{|r| return r }}}}

    # <form>
    case @r['CONTENT_TYPE']
    when 'application/x-www-form-urlencoded'
      formPOST

    # file upload
    when /^multipart\/form-data/
      dataPOST

    else # LDP Container POST
      isDir = @r.linkHeader['type'] == LDP+'BasicContainer'
      slug = @r['HTTP_SLUG']
      path = slug ? child(slug).setEnv(@r) : self

      if isDir
        body = @r['rack.input'].read
        path = child(rand.to_s.h[0..6]).setEnv(@r) unless slug

        if !body.empty?
          path.n3.w body
        end
        if !path.e
          path.MKCOL
        else
          [200,@r[:Response].update({Location: path.uri}),[]]
        end

      else
        path.PUT
      end
    end
  end

  def dataPOST
    p = (Rack::Request.new env).params
    if file = p['file']
      t = file[:tempfile]
      name = file[:filename]
      up = child name
      FileUtils.cp t, up.pathPOSIX
      t.unlink
      File.open(R[Time.now.strftime('/stat/POST.%Y%m%d.txt')].pathPOSIX, 'a'){|l|
        l.write "upload #{URI.escape up.uri} #{@r.user} #{@r['HTTP_USER_AGENT']}\n"} if '/stat'.R.e
      ldp
      [201,@r[:Response].update({Location: uri}),[]]
    end
  rescue
    [400,{},[]]
  end

  def formPOST
    form = Rack::Request.new(@r).params
    frag = form['fragment']
    return [400,{},['fragment-identifier missing']] unless frag
    frag = form[Title] if frag.empty? && form[Title]
    frag = frag.slugify

    subject = s = uri + '#' + frag
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

    # store doc-fragment
    ts = Time.now.iso8601.sub('-','.').sub('-','/').gsub /[+:T]/, ''
    fragPath = r.fragmentPath
    fragDoc = fragPath + '/' + ts + '.e' # frag-storage URI
    fragDoc.w graph, true # store fragment
    cur = fragPath.a '.e' # canonical frag-URI
    cur.delete if cur.e   # unlink obsolete version
    fragDoc.ln cur        # link current version

    buildDoc

    [303,{'Location'=>uri+'?edit'},[]]
  end

  def buildDoc
    graph = {}
    fragments.map{|f| f.fileToGraph graph}
    jsonDoc.w graph, true
  end
  
  def MKCOL
    return [403, {}, ["Forbidden"]] unless allowWrite
    return [405, {}, ["file exists"]] if file?
    return [405, {}, ["dir exists"]] if directory?
    mk
    ldp
    [201,@r[:Response].update({Location: uri}),[]]
  end

end
