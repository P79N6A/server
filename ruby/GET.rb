#watch __FILE__
class R

  def GET
    directory = uri[-1] == '/'
    [self,                                         # file at host-specific URI
     justPath,                                     # file at path
     (directory ? a('index.html') : nil)
    ].compact.map{|a| # check for candidate inodes
      if a.file?
        return a.setEnv(@r).fileGET # found
      elsif a.symlink?
        a.readlink.do{|t| return t.setEnv(@r).resourceGET} # goto target URI
      end}
    return warp if directory && q.has_key?('warp') # goto browser-UI
    stripDoc.setEnv(@r).resourceGET # file not found, goto generic-resource
  end

  def HEAD
    self.GET.do{|s,h,b|[s,h,[]]}
  end

  def fileGET
    @r[:Response].update({
      'Content-Type' => mime + '; charset=UTF-8',
      'ETag' => [m,size].h,
    })
    @r[:Response].update({'Cache-Control' => 'no-transform'}) if mime.match /^(audio|image|video)/
    condResponse ->{ self }
  end

  def resourceGET # lookup handler: cascading up paths, first with host, then without
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
    m = {'#' => {'uri' => uri}} # = this

    # File set
    fileFn = q['set'].do{|s| FileSet[s]} || FileSet['default']
    fileFn[self,q,m].do{|files| set.concat files }

    # Resource set
    q['set'].do{|s|
      ResourceSet[s].do{|resFn|
        resFn[self,q,m].do{|resources|
          resources.map{|resource|
            set.concat resource.fileResources}}}}

    m.delete('#') if m['#'].keys.size==1 # wipe unused metadata-resource

    @r[:Links].concat ["<#{aclURI}>; rel=acl", "<#{docroot}>; rel=meta"] # Link headers

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
      if q['view'] == 'edit' # editor requested
        (uri + '#').do{|u| # add a blank resource
          m[u] ||= {'uri' => u, Type => []}}
      else
        return E404[self,@r,m] # 404
      end
    end

    condResponse ->{ # Model -> View

      if NonRDF.member?(@r.format) && !q.has_key?('rdf') # JSON/Hash model
        set.map{|r|r.setEnv(@r).fileToGraph m} unless LazyView.member? q['view'] # payload
        Render[@r.format][m, @r]

      else # RDF model
        graph = RDF::Graph.new
        set.map{|r|(r.setEnv @r).justRDF.do{|doc| graph.load doc.pathPOSIX, :base_uri => self}} # payload

        # response metadata in Hash to RDF-graph
        R.resourceToGraph m['#'], graph

        # graph size
        @r[:Response][:Triples] = graph.size.to_s

        graph.dump (RDF::Writer.for :content_type => @r.format).to_sym, :base_uri => lateHost, :standard_prefixes => true, :prefixes => Prefixes
      end}
  end
  
  def condResponse body
    @r['HTTP_IF_NONE_MATCH'].do{|m|m.strip.split(/\s*,\s*/).include?(@r[:Response]['ETag']) && [304,{},[]]} ||
    body.call.do{|body|
      @r[:Status] ||= 200
      @r[:Response]['Content-Length'] ||= body.size.to_s
      body.class == R ? (Nginx ? [@r[:Status],@r[:Response].update({'X-Accel-Redirect' => '/fs/' + body.pathPOSIXrel}),[]] : # Nginx
                        Apache ? [@r[:Status],@r[:Response].update({'X-Sendfile' => body.d}),[]] : # Apache
                         (f = Rack::File.new nil; f.instance_variable_set '@path', body.d # Rack
                          f.serving(@r).do{|s,h,b|[s,h.update(@r[:Response]),b]})) :
      [@r[:Status],@r[:Response],[body]]}
  end

  View[HTTP+'Response'] = -> d,e {
    d['#'].do{|u| # Response Header
      [u[Prev].do{|p| # prev page
         {_: :a, rel: :prev, href: p.uri, c: [{class: :arrow, c: '&larr;'}, {class: :uri, c: p.R.offset}]}},
       u[Next].do{|n| # next page
         {_: :a, rel: :next, href: n.uri, c: [{class: :uri, c: n.R.offset}, {class: :arrow, c: '&rarr;'}]}},
       ([(H.css '/css/page', true), (H.js '/js/pager', true), (H.once e,:mu,(H.js '/js/mu', true))] if u[Next]||u[Prev])]}}

end
