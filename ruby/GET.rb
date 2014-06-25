#watch __FILE__
class R

  def GET
    ix = 'index.html'
    [self, justPath, *(uri[-1]=='/' ? [a(ix),justPath.a(ix)] : [])].compact.find(&:f).do{|file|
      return file.setEnv(@r).fileGET}
    uri = stripDoc # format-variant suffix
    uri = uri.parentURI.descend if uri.to_s.match(/\/index$/) # index
    uri.setEnv(@r).resourceGET # generic resource
  end

  def HEAD
    self.GET.do{|s,h,b|[s,h,[]]}
  end

  def fileGET
    @r[:Response].update({
      'Content-Type' => mimeP + '; charset=UTF-8',
      'ETag' => [m,size].h,
    })
    @r[:Response].update({'Cache-Control' => 'no-transform'}) if mimeP.match /^(audio|image|video)/
    condResponse ->{ self }
  end

  def resourceGET
    paths = justPath.cascade
    [@r['SERVER_NAME'],""].map{|h|
      paths.map{|p|
        GET[h + p].do{|fn|
#          puts "#{h}#{p} handling"
          fn[self,@r].do{|r|return r}}}}
    response
  end

  def response # default handler
    set = []
    m = {'#' => {'uri' => uri, Type => R[LDP+'Resource']}}

    # File set
    fileFn = q['set'].do{|s| FileSet[s]} || FileSet['default']
    fileFn[self,q,m].do{|files| set.concat files }

    # Resource set
    q['set'].do{|s|
      ResourceSet[s].do{|resFn|
        resFn[self,q,m].do{|resources|
          resources.map{|resource|
            set.concat resource.fileResources}}}}

    @r[:Links].concat ["<#{aclURI}>; rel=acl", "<#{docroot}>; rel=meta"]
    @r[:Links].push "<#{LDP+'BasicContainer'}>; rel=type" if uri[-1]=='/'
    @r[:Links].push "<#{LDP+'Resource'}>; rel=type"
    @r[:Response].
      update({ 'Accept-Patch' => 'application/json',
               'Accept-Post' => 'text/turtle, text/n3, application/json',
               'Access-Control-Allow-Origin' => @r['HTTP_ORIGIN'].do{|o|o.match(HTTP_URI) && o } || '*',
               'Access-Control-Allow-Credentials' => 'true',
               'Allow' => Allow,
               'Content-Type' => @r.format + '; charset=UTF-8',
               'ETag' => [set.sort.map{|r|[r, r.m]}, @r.format, q['view']].h})
    @r[:Response]['Link'] = @r[:Links].intersperse(', ').join

    if set.empty? # nothing found
      if q.has_key? 'new' # initialize
        m[uri+'#'] ||= {} # editable resource
        q['view'] ||= 'edit' # editable-view
      else
        return E404[self,@r,m] # 404
      end
    end

    condResponse ->{
      if NonRDF.member?(@r.format) && !q.has_key?('rdf')
        set.map{|r|r.setEnv(@r).fileToGraph m} unless %w{tabulate vowl}.member? q['view']
        Render[@r.format][m, @r]
      else
        graph = RDF::Graph.new # RDF Model->View
        set.map{|r|(r.setEnv @r).justRDF.do{|doc| graph.load doc.pathPOSIX, :base_uri => doc.base}}
        R.resourceToGraph m['#'], graph
        @r[:Response][:Triples] = graph.size.to_s
        graph.dump (RDF::Writer.for :content_type => @r.format).to_sym, :base_uri => lateHost, :standard_prefixes => true, :prefixes => Prefixes
      end}
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
