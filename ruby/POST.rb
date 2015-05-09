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
      graphPOST
    else
      [406,{'Accept-Post' => 'application/x-www-form-urlencoded, text/turtle, text/n3, multipart/form-data'},[]]
    end
  rescue Exception => e
    puts e.class, e.message
    [400,{},[]]
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

  def filePOST
    p = (Rack::Request.new env).params
    if file = p['file']
      FileUtils.cp file[:tempfile], child(file[:filename]).pathPOSIX
      file[:tempfile].unlink
      ldp
      [201,@r[:Response].update({Location: uri}),[]]
    end
  end

  def formPOST
    form = Rack::Request.new(@r).POST  # form data
    resource = {}                      # input resource
    type = (resource[Type] = ((form.delete Type) || Resource).R.expand).uri
    form.map{|p,o| # each triple
      o = if !o || o.empty?
            nil
          elsif o.match HTTP_URI
            o.R # URI
          elsif p == Content
            StripHTML[o] # sanitize HTML content
          else
            o.noHTML # string
          end
      resource[p] = o if o && p.match(HTTP_URI)}
    resource[WikiText].do{|c| # variable-type content
      datatype = form['datatype'] # type-tag
      c = StripHTML[c] if datatype == 'html' # clean up
      resource[WikiText] = {Content => c, 'datatype' => datatype}} # wrap with type
    targetResource = graph[uri] || {}
    isContainer = Containers[type]
    newContainer = false
    name = -> {resource[Title] && !resource[Title].empty? && resource[Title].slugify || rand.to_s.h[0..7]}

    subject = if form.uri # existing subject
                form.uri
              else # new subject
                @r[:Status] = 201 # mark as new
                if directory? # containee
                  newContainer = true if isContainer
                  resource[SIOC+'has_container'] = R[uri.t]
                  Create[type].do{|c|  c[resource,targetResource,@r]} # RDF-type constructor
                Identify[type].do{|id|id[resource,targetResource,@r]} || # custom containee URI
                  (uri.t + name[] + '#') # basic containee URI
                elsif isContainer # new container
                  newContainer = true
                  uri.t #container/ URI
                else # new resource
                  '#' + name[] # fragment URI
                end
              end

    located = (join subject).R.setEnv @r

    if resource.keys.size==1 # empty but typetag-field
      located.fragmentPath.a('.e').delete # unlink fragment
      located.buildDoc # update doc
      [303,{'Location' => uri},[]]

    else # update
      located.mk if newContainer # create container
      resource.update({ 'uri' => subject,         # URI
                        Creator => @r.user})      # author
      resource[Date] = Time.now.iso8601 if !isContainer # timestamp
      located.writeResource resource # write data
      [303,{'Location' => located.uri},[]] # return
    end
  end

end
