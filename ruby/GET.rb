#watch __FILE__
class R

  def GET
    i = 'index.html' # files at host-specific + global paths
    [self,
     justPath,
     *(uri[-1]=='/' ? [a(i),justPath.a(i)] : [])].compact.find(&:f).do{|file|
      a = @r.accept.values.flatten
      return file.setEnv(@r).fileGET if a.empty? || (a.member? file.mimeP) || (a.member? '*/*')} 
    uri = stripDoc # format-variant suffix
    uri = uri.parent.descend if uri.to_s.match(/\/index$/) # index
    uri.setEnv(@r).resourceGET # generic resource
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
    m = {'#' => {'uri' => '#', Type => R[LDP+'Resource']}}

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
      return E404[self,@r,m]
    end

    condResponse ->{
      if @r.format == 'text/html' && !@r.q.has_key?('rdfa')
        set.map{|r|r.setEnv(@r).fileToGraph m}
        Render[@r.format][m, @r] # HTML
      else
        graph = RDF::Graph.new   # RDF
        set.map{|r|
          r.setEnv(@r).rdfDoc.do{|doc|
            graph.load doc.d, :host => @r['SERVER_NAME'], :base_uri => doc.stripDoc}}
        describeResponse m, graph
        @r[:Response][:Triples] = graph.size.to_s
        graph.dump (RDF::Writer.for :content_type => @r.format).to_sym
      end}
  end

  def describeResponse res, graph
    res['#'].map{|p,o|
      o.justArray.map{|o|
        graph << RDF::Statement.new(self,p.R,[R,Hash].member?(o.class) ? o.R : RDF::Literal(o))} unless p=='uri'}
  end
  
  def condResponse body
    @r['HTTP_IF_NONE_MATCH'].do{|m|m.strip.split(/\s*,\s*/).include?(@r[:Response]['ETag']) && [304,{},[]]} ||
    body.call.do{|body|
      @r[:Status] ||= 200
      body.class == R ? (Nginx ? [@r[:Status],@r[:Response].update({'X-Accel-Redirect' => '/fs/' + body.pathPOSIXrel}),[]] : # Nginx
                        Apache ? [@r[:Status],@r[:Response].update({'X-Sendfile' => body.d}),[]] : # Apache
                         (f = Rack::File.new nil; f.instance_variable_set '@path', body.d # Rack
                          f.serving(@r).do{|s,h,b|[s,h.update(@r[:Response]),b]})) :
      [@r[:Status],@r[:Response],[body]]}
  end

end
