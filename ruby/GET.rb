#watch __FILE__
class R

  def GET
    directory = uri[-1] == '/'
    [self, justPath, # host-specific and global-path files
     (directory ? a('index.html') : nil) # HTML dir-index
    ].compact.map{|a|
      if a.file?
        return a.setEnv(@r).fileGET # goto file
      elsif a.symlink?
        a.readlink.do{|t|return t.setEnv(@r).resourceGET} # goto target URI
      end}
    stripDoc.setEnv(@r).resourceGET # goto generic-resource
  end

  def fileGET
    @r[:Response].update({
      'Content-Type' => mime + '; charset=UTF-8',
      'ETag' => [m,size].h})
    @r[:Response].update({'Cache-Control' => 'no-transform'}) if mime.match /^(audio|image|video)/
    @r[:Links].concat ["<#{aclURI}>; rel=acl", "<#{docroot}>; rel=meta"] # Link headers
    @r.ldp
    condResponse ->{ self } # continue if uncached
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
    m = {'#' => {'uri' => uri}} # request-meta

    # File(s)
    fileFn = q['set'].do{|s| FileSet[s]} || FileSet['default']
    fileFn[self,q,m].do{|files| set.concat files }

    # Resource(s)
    q['set'].do{|s|
      ResourceSet[s].do{|resFn|
        resFn[self,q,m].do{|resources|
          resources.map{|resource|
            set.concat resource.fileResources}}}}

    m.delete('#') if m['#'].keys.size==1 # empty request-meta

    @r[:Links].concat ["<#{aclURI}>; rel=acl", "<#{docroot}>; rel=meta"] # Link headers
    @r.ldp # LDP headers
    @r[:Response].update({ 'Content-Type' => @r.format + '; charset=UTF-8',
                           'ETag' => [set.sort.map{|r|[r, r.m]}, @r.format, q['view']].h})

    if set.empty? # nothing found
      if q.has_key? 'edit' # editor requested
        q['view'] ||= 'edit'
      else
        return E404[self,@r,m] # 404
      end
    end

    # Model -> View , lazy continuation
    condResponse ->{

      # Hash graph
      if NonRDF.member? @r.format
        if LazyView.member?(q['view']) || q.has_key?('empty') # identifiers only
          set.map{|f|
            f.fromStream m, :triplrInode
            f.stripDoc.do{|r| m[r] ||= {'uri' => r, Type => Resource}}}
        else
#          puts "set " + set.join(' ')
          set.map{|r|r.setEnv(@r).fileToGraph m} # Model
        end
        Render[@r.format][m, @r] # View

      else # RDF graph
        graph = RDF::Graph.new # Model
        set.map{|r|(r.setEnv @r).justRDF.do{|doc| graph.load doc.pathPOSIX, :base_uri => self}} # construct model
        @r[:Response][:Triples] = graph.size.to_s
        graph.dump (RDF::Writer.for :content_type => @r.format).to_sym, :base_uri => lateHost, :standard_prefixes => true, :prefixes => Prefixes # View
      end}
  end
  
  def condResponse body
    etags = @r['HTTP_IF_NONE_MATCH'].do{|m| m.strip.split /\s*,\s*/ }
    if etags && (etags.include? @r[:Response]['ETag'])
      [304, {}, []]
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

  View[HTTP+'Response'] = -> d,e {
    d['#'].do{|u|
      [u[Prev].do{|p| # prev page
         {_: :a, rel: :prev, href: p.uri, c: ['&larr;', {class: :uri, c: p.R.offset}]}},
       u[Next].do{|n| # next page
         {_: :a, rel: :next, href: n.uri, c: [{class: :uri, c: n.R.offset}, '&rarr;']}},
       ([(H.css '/css/page', true), (H.js '/js/pager', true), (H.once e,:mu,(H.js '/js/mu', true))] if u[Next]||u[Prev])]}}

  # graph -> RDF representation (generic)
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

  # graph -> RDF representation (MIME)
  [['application/ld+json',:jsonld],['application/rdf+xml',:rdfxml],['text/plain',:ntriples],['text/turtle',:turtle],['text/n3',:n3]].
    map{|mime|
    Render[mime[0]] = ->d,e{ R.renderRDF d, mime[1], e}}

end
