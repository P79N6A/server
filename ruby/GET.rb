#watch __FILE__
class R

  def GET
    directory = uri[-1] == '/'
    [self, justPath, # host-specific and global-path files
     (directory ? a('index.html') : nil) # HTML dir-index
    ].compact.map{|a|
      if a.file?
        return a.setEnv(@r).fileGET                       # goto static-file
      elsif a.symlink?
        a.readlink.do{|t|return t.setEnv(@r).resourceGET} # goto target URI
      end}
    stripDoc.setEnv(@r).resourceGET                       # goto generic-resource
  end

  def fileGET
    @r[:Response].
      update({ 'Content-Type' => mime + '; charset=UTF-8',
               'ETag' => [m,size].h,
             })
    @r[:Response].update({'Cache-Control' => 'no-transform'}) if mime.match /^(audio|image|video)/
    ldp
    condResponse ->{ self }
  end

  def resourceGET
    paths = justPath.cascade
    [@r['SERVER_NAME'],""].map{|h|
      paths.map{|p| GET[h+p].do{|fn| fn[self,@r].do{|r| return r }}}} # handler-lookup cascade
    response # default handler
  end

  def response
    set = [] # result set
    m = {'#' => {'uri' => uri, Type => R[HTTP+'Response']}}
    rdf = !(NonRDF.member? @r.format) # graph type

    # File(s)
    (q['set'].do{|s|FileSet[s]} || FileSet['default'])[self,q,m].do{|files| set.concat files }

    # Resource(s)
    q['set'].do{|s|
      ResourceSet[s].do{|resFn|
        resFn[self,q,m].do{|resources|
          resources.map{|resource|
            set.concat resource.fileResources}}}}

    if set.empty? # nothing found
      if q.has_key? 'edit' # init editor
        q['view'] ||= 'edit'
      else
        return E404[self,@r,m]
      end
    end

    etagX = rdf ? [] : [q['rev'], q['sort'], q['view']] # representation-varying inputs
    @r[:Response].update({ 'Content-Type' => @r.format + '; charset=UTF-8',           # output MIME
                           'ETag' => [set.sort.map{|r|[r,r.m]}, @r.format, etagX].h}) # representation id
    ldp # capability headers

    condResponse ->{
      if rdf
        graph = RDF::Graph.new
        if set.size==1 && @r.format == set[0].mime # no merge or transcode needed
          set[0] # file
        else
          if @r[:directory] # add metadata on contained-resources
            set.map{|f|(f.setEnv @r).streamToRDF graph, :triplrInode}
          else # expand model-thunks (resource URIs) to graph
            set.map{|f|(f.setEnv @r).justRDF.do{|doc|graph.load doc.pathPOSIX, :base_uri => self}}
          end
          @r[:Response][:Triples] = graph.size.to_s
          graph.dump (RDF::Writer.for :content_type => @r.format).to_sym, :base_uri => lateHost, :standard_prefixes => true, :prefixes => Prefixes
        end
      else # Hash
        set.map{|r|r.setEnv(@r).fileToGraph m}
        set.map{|f|f.fromStream m, :triplrInode} if @r[:directory]
        Render[@r.format][m, @r]
      end}
  end
  
  def condResponse body
    etags = @r['HTTP_IF_NONE_MATCH'].do{|m| m.strip.split /\s*,\s*/ }
    if etags && (etags.include? @r[:Response]['ETag'])
      [304, @r[:Response], []]
    else
      body = body.call
      @r[:Status] ||= 200
      @r[:Response]['Content-Length'] ||= body.size.to_s
      if body.class == R
        if Apache
          [@r[:Status], @r[:Response].update({'X-Sendfile' => body.pathPOSIX}), []]
        elsif Nginx
          [@r[:Status], @r[:Response].update({'X-Accel-Redirect' => '/fs/' + body.pathPOSIXrel}), []]
        else
          f = Rack::File.new nil
          f.instance_variable_set '@path', body.pathPOSIX
          f.serving(@r).do{|s,h,b|
            [s, h.update(@r[:Response]), b]}
        end
      else
        [@r[:Status], @r[:Response], [body]]
      end
    end
  end

  # graph -> RDF format
  def R.renderRDF d,f,e
    (RDF::Writer.for f).buffer{|w| # init writer
      d.triples{|s,p,o|            # structural triples of Hash::Graph
        s && p && o &&             # all fields non-nil
        (s = RDF::URI s            # subject-URI
         p = RDF::URI p            # predicate-URI
         o = (if [R,Hash].member? o.class
                RDF::URI o.uri     # object URI ||
              else                 # object Literal
                l = RDF::Literal o
                l.datatype=RDF.XMLLiteral if p == Content
                l
              end) rescue nil
         (w << (RDF::Statement.new s,p,o) if o) rescue nil )}}
  end

  [['application/ld+json',:jsonld],['application/rdf+xml',:rdfxml],['text/plain',:ntriples],['text/turtle',:turtle],['text/n3',:n3]].
    map{|mime|
    Render[mime[0]] = ->d,e{ R.renderRDF d, mime[1], e}}

end
