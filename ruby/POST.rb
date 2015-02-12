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
            o.R                  # URI
          elsif p == Content
            StripHTML[o]         # HTML
          else
            o                    # String
          end
      resource[p] = o if o && p.match(HTTP_URI)
    }
  end

  def formPOST
    data = Rack::Request.new(@r).POST   # form
    type = (data.delete Type)||Resource # RDF-resource type
    datatype = data.delete 'datatype'   # content-literal datatype
    resource = {}                       # resource
    targetResource = graph[uri] || {}   # target
    R.formResource data, resource       # cast form to RDF graph

    # subject URI
    subject = if data.uri # URI provided,
                data.uri  # use existing
              else # mint a URI, creating
                @r[:Status] = 201 # mark as new
                slug = resource[Title] && !resource[Title].empty? && resource[Title].slugify || rand.to_s.h[0..7] # name
                if e # POST to container
                  resource[SIOC+'has_container'] = R[uri.t] # containment metadata
                  targetResource[Type].justArray.map(&:maybeURI).compact.map{|c| # type(s) of container
                    POST[c].do{|h| h[resource,targetResource,@r]}} # target handler
                  if resource.uri # URI bound by handler
                    resource.uri
                  else # mint URI for contained resource
                    uri.t + slug + '#'
                  end
                elsif Containers[resource[Type].maybeURI] # new container
                  mk                                      # make fs container
                  uri.t                                   # add trailing-slash
                else # basic resource
                  uri + '#' + slug
                end
              end

    if resource.empty? # blank resource
      subject.R.fragmentPath.a('.e').delete # unlink live-version (history remains)
      subject.R.buildDoc # update (maybe unlink) doc
      [303,{'Location' => uri},[]]
    else
      resource.update({ 'uri' => subject,         # URI
                        Type => type.R.expand,    # RDF type
                        Date => Time.now.iso8601, # timestamp
                        Creator => @r.user})      # author
      resource[WikiText].do{|c|
        resource[WikiText] = {Content => c,
                             'datatype' => datatype}}
      R.writeResource resource # write
      [303,{'Location' => resource.uri},[]] # return
    end
  end

  def R.writeResource r, buildDoc = true
    graph = {r.uri => r}         # resource to graph
    ts = Time.now.iso8601.gsub /[-+:T]/, '' # timestamp slug
    path = r.R.fragmentPath      # version base
    doc = path + '/' + ts + '.e' # version
    doc.w graph, true            # write version
    cur = path.a '.e'            # live-resource
    cur.delete if cur.e          # obsolete version
    doc.ln_s cur                 # make version live
    r.R.buildDoc if buildDoc     # update containing-doc
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
