#watch __FILE__
class R

  def GET
    i = 'index.html' # look for files at host-specific & global path
    if file = [self,justPath,*(uri[-1]=='/' ? [a(i),justPath.a(i)] : [])].compact.find(&:f) # most-specific wins
      a = @r.accept.values.flatten # Accept header
      accepted = a.empty? || (a.member? file.mimeP) || (a.member? '*/*') # server or client might want transcode to acceptable MIME
      return file.setEnv(@r).fileGET unless !accepted || (MIMEcook[file.mimeP] && !(q.has_key? 'raw')) # accepted
    end # conneg-hint paths
    uri = stripDoc # doc-format in extension
    uri = uri.parent.descend if uri.to_s.match(/\/index$/) # virtual index (to add extension to)
    uri.setEnv(@r).resourceGET # generic-resource
  end

  def HEAD
    self.GET.do{|s,h,b|[s,h,[]]}
  end

  def fileGET
    @r[:Response].update({
      'Content-Type' => mimeP,
      'ETag' => [m,size].h,
    })
    @r[:Response].update({'Cache-Control' => 'no-transform'}) if mimeP.match /^(audio|image|video)/
    condResponse ->{ self }
  end

  def resourceGET
    paths = justPath.cascade
    [@r['SERVER_NAME'],""].map{|h|
      paths.map{|p| GET[h + p].do{|fn|
#          puts "#{h}#{p} handling"
          fn[self,@r].do{|r|return r}}}}
    response
  end

  def response # default handler
    set = []
    m = {'#' => {'uri' => '#', Type => R[HTTP+'Response']}} # Response model in RDF

    # File  directly-mapped filesystem resources
    fileFn = q['set'].do{|s| FileSet[s]} || FileSet['default']
    fileFn[self,q,m].do{|files| set.concat files }

    # Resource  custom generic-resource set (search / index handlers)
    q['set'].do{|s|
      ResourceSet[s].do{|resFn|
        resFn[self,q,m].do{|resources|
          resources.map{|resource|
            set.concat resource.fileResources}}}}

    @r[:Links].push "<#{aclURI}>; rel=acl" # WAC
    @r[:Response].update({
        'Access-Control-Allow-Origin' => @r['HTTP_ORIGIN'].do{|o|o.match(HTTP_URI) && o } || '*',
        'Content-Type' => @r.format,
        'ETag' => [q['view'].do{|v|View[v] && v}, set.sort.map{|r|[r, r.m]}, @r.format].h,
        'MS-Author-Via' => 'SPARQL',
    })
    @r[:Response]['Link'] = @r[:Links].intersperse(', ').join # Link Header

    if set.empty?
#      if @r['HTTP_ACCEPT'].do{|f|f.match(/text\/n3/)} || @r.format == 'text/n3'
#        return [200,@r[:Response],['']] # resource-thunk for data-browsers
#      else
        return E404[self,@r,m]
#      end
    end

    condResponse ->{
      if (@r.format != 'text/html') && writer = (RDF::Writer.for :content_type => @r.format)
        graph = RDF::Graph.new
        set.map{|r|
          doc = r.setEnv(@r).rdfDoc # resources
          graph.load doc.d, :host => @r['SERVER_NAME'], :base_uri => doc.stripDoc if doc.e} # populate

        m['#'].map{|p,o| o.justArray.map{|o| graph << RDF::Statement.new(@r[:Response]['URI'].R, p.R,
                    [R,Hash].member?(o.class) ? o.R : RDF::Literal(o))} unless p=='uri'} # current env -> RDF

        @r[:Response][:Triples] = graph.size.to_s # size
        graph.dump writer.to_sym # RDF
      else
        set.map{|r|r.setEnv(@r).fileToGraph m}
        Render[@r.format][m, @r] # HTML
      end}
  end
  
  def condResponse body
    @r['HTTP_IF_NONE_MATCH'].do{|m|m.strip.split(/\s*,\s*/).include?(@r[:Response]['ETag']) && [304,{},[]]} ||
    body.call.do{|body|
      body.class == R ? (Nginx ? [200,@r[:Response].update({'X-Accel-Redirect' => '/fs/' + body.pathPOSIXrel}),[]] : # Nginx
                        Apache ? [200,@r[:Response].update({'X-Sendfile' => body.d}),[]] : # Apache
                         (f = Rack::File.new nil; f.instance_variable_set '@path', body.d # Rack
                          f.serving(@r).do{|s,h,b|[s,h.update(@r[:Response]),b]})) :
      [200,@r[:Response],[body]]}
  end

end
