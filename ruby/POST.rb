#watch __FILE__
class R

  def POST
    return [403,{},[]] unless @r.signedIn && allowWrite
    case @r['CONTENT_TYPE']
    when /^application\/x-www-form-urlencoded/
      formPOST
    when /^multipart\/form-data/
      filePOST
    when /^text\/(n3|turtle)/
      rdfPOST
    else
      [406,{'Accept-Post' => 'application/x-www-form-urlencoded, text/turtle, text/n3, multipart/form-data'},[]]
    end
  end

  def rdfPOST
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
      file[:tempfile].unlink
      ldp
      [201,@r[:Response].update({Location: uri}),[]]
    end
  end

  def R.formResource form, resource
    form.map{|p,o|                      # form-data to resource
      o = if !o || o.empty?
            nil
          elsif o.match HTTP_URI
            o.R # URI
          elsif p == Content
            StripHTML[o] # HTML
          else
            o   # String
          end
      resource[p] = o if o && p.match(HTTP_URI)
    }
    resource[WikiText].do{|c| resource[WikiText] = {Content => c, 'datatype' => form['datatype']}}
  end

  def formPOST
    data = Rack::Request.new(@r).POST  # form
    type = data.delete(Type)||Resource # RDF-resource type
    resource = {Type => type.R.expand} # resource
    targetResource = graph[uri] || {}  # target
    R.formResource data, resource      # cast form to RDF graph

    slug = -> {resource[Title] &&
              !resource[Title].empty? &&
               resource[Title].slugify || rand.to_s.h[0..7]}

    subject = if data.uri # existing subject
                data.uri
              else # create resource
                @r[:Status] = 201 # mark as new
                if directory? # container POST
                  resource[SIOC+'has_container'] = R[uri.t] # container pointer
                  targetResource[Type].justArray.map(&:maybeURI).compact.map{|c| # lookup type-handlers
                    POST[c].do{|h| h[resource,targetResource,@r]}} # run type-handler
                  resource.uri || (uri.t + slug[] + '#') # contained-resource
                elsif Containers[resource[Type].maybeURI] # create container
                  mk; uri.t
                else # generic resource
                  '#' + slug[]
                end
              end
    located = (join subject).R.setEnv @r

    if resource.keys.size==1 && resource[Type] # empty resource
      located.fragmentPath.a('.e').delete # obsoleted-version URI
      located.buildDoc # update doc
      [303,{'Location' => uri},[]]
    else # update resource
      resource.update({ 'uri' => subject,         # URI
                        Date => Time.now.iso8601, # timestamp
                        Creator => @r.user})      # author
      located.writeResource resource # write
      [303,{'Location' => located.uri},[]] # return
    end
  end

  def writeResource re, build = true
    ts = Time.now.iso8601.gsub /[-+:T]/, '' # timestamp slug
    path = fragmentPath          # version-base URI
    doc = path + '/' + ts + '.e' # version-doc URI
    rel = uri # keep full-URI (faster)
#    rel = URI(stripFrag.uri).route_to(uri).to_s # find relative-URI
#    re['uri'] = rel     # localize identifier
    graph = {rel => re} # graph
    doc.w graph, true   # write graph
    cur = path.a '.e'   # live-version URI
    cur.delete if cur.e # unlink obsolete-version
    doc.ln_s cur        # link live-version
    buildDoc if build   # update containing-doc
  end

  def buildDoc
    resources = fragments
    doc = jsonDoc
    if !resources || resources.empty? # empty
      doc.delete                      # unlink
    else
      graph = {}
      resources.map{|f| f.nodeToGraph graph} # mash fragments
      doc.w graph, true                      # write doc
    end
  end

  def fragmentDir # all fragments
    doc = docroot
    doc.dir.descend + '.' + doc.basename + '/'
  end
  def fragments; fragmentDir.a('*.e').glob end

  def fragmentPath # one fragment
    f = fragment
    f = 'index' if !f
    f = '#' if f.empty?
    fragmentDir + f
  end

end
