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

  def R.formToGraph form, resource
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
  end

  def formPOST
    data = Rack::Request.new(@r).POST  # form
    type = data.delete(Type)||Resource # RDF-resource type
    resource = {Type => type.R.expand} # resource
    targetResource = graph[uri] || {}  # target
    R.formToGraph data, resource       # form-data

    slug = -> {resource[Title] && !resource[Title].empty? &&
               resource[Title].slugify || rand.to_s.h[0..7]}

    subject = if data.uri # existing subject
                data.uri
              else # new subject
                @r[:Status] = 201 # mark as new
                if directory? # container target
                  resource[SIOC+'has_container'] = R[uri.t] # containment
                  targetResource[Type].justArray.map(&:maybeURI).compact.map{|c| # lookup type-handlers
                    POST[c].do{|h| puts "POST to #{c} at #{uri}"
                      h[resource,targetResource,@r]}} # typed POST-handler
                  resource.uri || (uri.t + slug[] + '#') # contained-resource URI
                elsif Containers[resource[Type].maybeURI] # create a container
                  mk; uri.t # create fs-container, ensure trailing-slash URI
                else # create generic resource URI
                  '#' + slug[] # fragment in doc
                end
              end
    located = (join subject).R.setEnv @r

    if resource.keys.size==1 && resource[Type] # empty resource?
      located.fragmentPath.a('.e').delete # unlink current
      located.buildDoc # update doc
      [303,{'Location' => uri},[]]
    else # update
      resource.update({ 'uri' => subject,         # URI
                        Date => Time.now.iso8601, # timestamp
                        Creator => @r.user})      # author
      located.writeResource resource # write
      [303,{'Location' => located.uri},[]] # return
    end
  end

end
