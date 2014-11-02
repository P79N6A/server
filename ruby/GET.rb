watch __FILE__
class R

  def GET
    if file?
      fileGET
    elsif justPath.file?
      justPath.setEnv(@r).fileGET
    elsif directory?
      if uri[-1] == '/'
        @r[:container] = true
        resourceGET
      else
        [301, {'Location' => uri + '/?' + @r['QUERY_STRING']}, []]
      end
    else
      stripDoc.setEnv(@r).resourceGET
    end
  end

  def fileGET
    @r[:Response].
      update({ 'Content-Type' => mime + '; charset=UTF-8',
               'ETag' => [m,size].h })
    @r[:Response].update({'Cache-Control' => 'no-transform'}) if mime.match /^(audio|image|video)/
    ldp
    condResponse ->{ self }
  end

  def resourceGET
    paths = justPath.cascade
    [@r['SERVER_NAME'],""].map{|h|
      paths.map{|p| GET[h+p].do{|fn| fn[self,@r].do{|r| return r }}}} # search for handlers

    response
  end

  def response
    set = [] # files
    m = {'#' => {'uri' => uri, Type => R[LDP+'Resource']}} # Hash graph
    rdf = !(NonRDF.member? @r.format) # graph-type

    s = q['set']
    rs = ResourceSet[s]
    fs = FileSet[s]

    FileSet['default'][self,q,m].do{|f|set.concat f} unless rs||fs
    fs[self,q,m].do{|files|set.concat files} if fs
    rs[self,q,m].do{|l|l.map{|r|set.concat r.fileResources}} if rs

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
      if set.size==1 && @r.format == set[0].mime
        set[0] # direct pass-through
      else
        if rdf
          graph = RDF::Graph.new
          set.map{|f|
            f = f.setEnv(@r)
            f.fromStreamRDF graph, :triplrInode if @r[:container]
            f.justRDF.do{|doc|graph.load doc.pathPOSIX, :base_uri => self}}
          graph << (RDF::Statement.new R['..'],Type,R[Stat+'Directory'])
          @r[:Response][:Triples] = graph.size.to_s
          graph.dump (RDF::Writer.for :content_type => @r.format).to_sym, :base_uri => lateHost, :standard_prefixes => true, :prefixes => Prefixes
        else # Hash
          set.map{|r|r.setEnv(@r).fileToGraph m}
          set.map{|f|f.fromStream m, :triplrInode} if @r[:container]
          m['..'] = {'uri' => '..', Type => R[Stat+'Directory']}
          Render[@r.format][m, @r]
        end
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

end
