watch __FILE__
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

  def R.formToGraph form, resource

  end

  def formPOST
    form = Rack::Request.new(@r).POST  # form data
    type = form.delete(Type)||Resource # RDF-type
    resource = {Type => type.R.expand}
    resource = R.formToGraph form
    form.map{|p,o|
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
    resource[WikiText].do{|c|
      resource[WikiText] = {Content => c, 'datatype' => form['datatype']}}
    # input resource
    targetResource = graph[uri] || {}  # target resource

    isContainer = Containers[resource[Type].maybeURI] # subject is container
    newContainer = false

    slug = -> {resource[Title] && !resource[Title].empty? &&
               resource[Title].slugify || rand.to_s.h[0..7]}

    subject = if form.uri # existing subject
                form.uri
              else # new subject
                @r[:Status] = 201 # mark as new

                if directory? # new container-member
                  newContainer = true if isContainer
                  resource[SIOC+'has_container'] = R[uri.t] # container pointer

                  # typed container-handlers
                  targetResource[Type].justArray.map(&:maybeURI).compact.map{|c|
                    POST[c].do{|h|
                      puts "POST to a #{c} at #{uri}"
                      h[resource,targetResource,@r]}} # handle
                  
                  if resource.uri # bespoke-handler minted URI
                    resource.uri  # bespoke URI
                  else
                    (uri.t + slug[] + '#') # container/doc#
                  end

                elsif isContainer # new container
                  newContainer = true
                  uri.t           # container/
                else # new basic-resource
                  '#' + slug[]    # doc#fragment
                end
              end

    located = (join subject).R.setEnv @r

    if resource.keys.size==1 && resource[Type] # delete
      located.fragmentPath.a('.e').delete # unlink frag-doc
      located.buildDoc # update resource-doc
      [303,{'Location' => uri},[]]

    else # update
      located.mk if newContainer # create container
      resource.update({ 'uri' => subject,         # URI
                        Date => Time.now.iso8601, # timestamp
                        Creator => @r.user})      # author
      located.writeResource resource # write data
      [303,{'Location' => located.uri},[]] # return
    end
  end

end
