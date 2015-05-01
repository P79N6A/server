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
    puts "<form> POST to #{uri}"
    data = Rack::Request.new(@r).POST  # form
    type = data.delete(Type)||Resource # RDF-resource type
    resource = {Type => type.R.expand} # resource
    targetResource = graph[uri] || {}  # target
    R.formToGraph data, resource       # form-data
    isContainer = Containers[resource[Type].maybeURI] # subject is container
    makeContainer = false # subject is a new container

    slug = -> {resource[Title] && !resource[Title].empty? &&
               resource[Title].slugify || rand.to_s.h[0..7]}

    subject = if data.uri # existing subject
                puts "URI exists #{data.uri}"
                data.uri
              else # new subject
                puts "201 Creating.."
                @r[:Status] = 201 # mark as new
                if directory? # new container-member
                  puts "new containee"
                  resource[SIOC+'has_container'] = R[uri.t] # containment

                  # lookup typed-container handler
                  targetResource[Type].justArray.map(&:maybeURI).compact.map{|c|
                    POST[c].do{|h| puts "POST to #{c} at #{uri}"
                      h[resource,targetResource,@r]}} # container handler
                  
                  if resource.uri # bespoke-handler may have minted URI
                    resource.uri # bespoke URI
                  else
                    (uri.t + slug[] + '#') # containee URI
                  end
                  makeContainer = true if isContainer # new container (in container..)
                elsif isContainer # new container
                  puts "new container"
                  makeContainer = true
                  uri.t # container/
                else # new basic-resource
                  puts "new generic resource"
                  '#' + slug[] # doc#fragment
                end
              end

    located = (join subject).R.setEnv @r

    if resource.keys.size==1 && resource[Type] # empty resource?
      located.fragmentPath.a('.e').delete # unlink current
      located.buildDoc # update doc
      [303,{'Location' => uri},[]]
    else # update
      located.mk if makeContainer # create fs-container
      resource.update({ 'uri' => subject,         # URI
                        Date => Time.now.iso8601, # timestamp
                        Creator => @r.user})      # author
      located.writeResource resource # write data
      [303,{'Location' => located.uri},[]] # return
    end
  end

end
