#watch __FILE__
class R

  def POST
    return [403,{},[]] unless @r.signedIn && allowWrite
    mime = @r['CONTENT_TYPE']
    case mime
    when /^application\/x-www-form-urlencoded/
      formPOST
    when /^multipart\/form-data/
      filePOST
    when /^text\/(n3|turtle)/
      graphPOST
    when /^application\/sparql-update/
      sparqlPOST
    else
#      puts "rare MIME #{mime}"
      [406,{'Accept-Post' => 'application/x-www-form-urlencoded, text/turtle, text/n3, multipart/form-data'},[]]
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

  # edit our subset of RDF in classic <form> workflow
  def formPOST
    form = Rack::Request.new(@r).POST  # form data
    resource = {}                      # source graoh
    type = (resource[Type] = ((form.delete Type) || WikiArticle).R.expand).uri # source type
    isContainer = Containers[type] # is source a container/

    # form data to RDF graph
    form.map{|p,o| # each triple
      o = if !o || o.empty? # skip null
            nil
          elsif o.match HTTP_URI
            o.R # RDF URI
          elsif p == Content
            StripHTML[o] # sanitize HTML
          elsif p == WikiText
            o # variable-typed, finish later
          else
            o.noHTML # (HTML-escaped) string
          end
      # triple to graph
      resource[p] = o if o && p.match(HTTP_URI)} # predicates must be HTTP URIs!

    # variable-typed content-field
    resource[WikiText].do{|c|
      datatype = form['datatype'] # lookup type-tag
      c = StripHTML[c] if datatype == 'html' # sanitize HTML
      resource[WikiText] = {Content => c, 'datatype' => datatype}} # wrap value with type-tag

    makeContainer = false
    slug = -> {resource[Title] && !resource[Title].empty? && resource[Title].slugify || rand.to_s.h[0..7]}

    # bind resource-identifier
    subject = if form.uri # existing subject
                form.uri # keep it
              else # new subject
                @r[:Status] = 201 # mark as new
                makeContainer = true if isContainer # create underlying container
                if directory? # new containee
                  resource[SIOC+'has_container'] = R[uri.t] # point to container
                  if identifier = Identify[type] # URI-minter found
                    identifier[resource,graph[uri],@r] # bespoke URI
                  else # basic containee
                    if isContainer
                      uri.t + slug[] + '/' # contained-container
                    else
                     uri.t + slug[] + '#' # resource in doc
                    end
                  end
                elsif isContainer # new container
                  uri.t # container/ URI
                else # new resource
                  '#' + slug[] # #fragment URI
                end
              end

    # find absolute-location of resource
    located = (join subject).R.setEnv @r # resolve relative-URI

    if (resource.keys - [Type,Creator,Date,Mtime]).empty? # empty
#      puts :Empty
      located.fragmentPath.a('.e').delete # unlink fragment-doc
      located.buildDoc # update doc
      [303,{'Location' => uri},[]]

    else # update resource
#      puts :Update
      located.mk if makeContainer # create container
      resource.update({ 'uri' => subject,         # URI
                        Creator => @r.user})      # author
      if !isContainer # use filesystem-time on containers
        mt = Time.now # timestamp
        resource[Date] = mt.iso8601 # dc:date     2016-01-01T00:00:00
        resource[Mtime] = mt.to_i   # posix:mtime seconds since 1970
      end
      located.writeResource resource # write data (see PUT.rb)
      [303,{'Location' => located.uri},[]] # done
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

end
