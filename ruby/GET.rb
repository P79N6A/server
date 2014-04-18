#watch __FILE__
class R

  def GET
    if file = [self,pathSegment].compact.find(&:f) # file exists at URI, but client (or server) might want another MIME
      a = @r.accept.values.flatten
      accepted = a.empty? || (a.member? file.mimeP) || (a.member? '*/*')
      return file.setEnv(@r).fileGET unless !accepted || (MIMEcook[file.mimeP] && !(q.has_key? 'raw'))
    end # enable conneg-hint paths:
    uri = stripDoc # doc-format in extension
    uri = uri.parent.descend if uri.to_s.match(/\/index$/)
    uri.setEnv(@r).resourceGET # continue at generic-resource URI
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

  def resourceGET # handler cascade
    paths = pathSegment.cascade
    [@r['SERVER_NAME'],""].map{|h|
      paths.map{|p| GET[h + p].do{|fn|
#          puts "#{h}#{p} handling"
          fn[self,@r].do{|r|return r}}}}
    response
  end

  def response # default handler
    set = []
    m = {'#' => {'uri' => '#', Type => R[HTTP+'Response']}} # Response model in RDF

    # File
    fileFn = q['set'].do{|s| FileSet[s]} || FileSet['default']
    fileFn[self,q,m].do{|files| set.concat files }

    # Resource
    q['set'].do{|s|
      ResourceSet[s].do{|resFn|
        resFn[self,q,m].do{|resources|
          resources.map{|resource|
            set.concat resource.fileResources}}}}

    @r[:Links].push "<#{aclURI}>; rel=acl"
    @r[:Response].update({
        'Access-Control-Allow-Origin' => @r['HTTP_ORIGIN'].do{|o|o.match(HTTP_URI) && o } || '*',
        'Content-Type' => @r.format,
        'ETag' => [q['view'].do{|v|View[v] && v}, set.sort.map{|r|[r, r.m]}, @r.format].h,
        'MS-Author-Via' => 'SPARQL',
    })
    @r[:Response]['Link'] = @r[:Links].intersperse(', ').join

    if set.empty?
      if @r['HTTP_ACCEPT'].do{|f|f.match(/text\/n3/)} || @r.format == 'text/n3'
        return [200,@r[:Response],['']] # editable resource
      else
        return E404[self,@r,m]
      end
    end

    condResponse ->{
      writer = RDF::Writer.for :content_type => @r.format
      if writer && ((@r.format != 'text/html') || q.has_key?('rdfa'))
        graph = RDF::Graph.new             # Model
        set.map{|r| graph.load r.rdfDoc.d, :host => @r['SERVER_NAME']} # resource state
        m['#'].map{|p,o| o.justArray.map{|o| graph << RDF::Statement.new(@r[:Response]['URI'].R, p.R,
                    [R,Hash].member?(o.class) ? o.R : RDF::Literal(o))} unless p=='uri'} # request data
        @r[:Response][:Triples] = graph.size.to_s # graph size
        graph.dump writer.to_sym           # RDF
      else
        set.map{|r|r.setEnv(@r).fileToGraph m}
        Render[@r.format][m, @r] # HTML
      end}
  end
  
  def condResponse body
    @r['HTTP_IF_NONE_MATCH'].do{|m|m.strip.split(/\s*,\s*/).include?(@r[:Response]['ETag']) && [304,{},[]]} ||
    body.call.do{|body|
      body.class == R ? (Nginx ? [200,@r[:Response].update({'X-Accel-Redirect' => '/fs' + body.path}),[]] : # Nginx
                        Apache ? [200,@r[:Response].update({'X-Sendfile' => body.d}),[]] : # Apache
                         (f = Rack::File.new nil; f.instance_variable_set '@path', body.d # Rack
                          f.serving(@r).do{|s,h,b|[s,h.update(@r[:Response]),b]})) :
      [200,@r[:Response],[body]]}
  end

end
