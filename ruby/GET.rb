# coding: utf-8
#watch __FILE__
class R

  def GET
    ldp
    if file?
      fileGET
    elsif justPath.file?
      justPath.setEnv(@r).fileGET
    elsif directory?
      if uri[-1] == '/'
        @r[:container] = true
        resourceGET
      else
        @r[:Response].update({'Location' => uri + '/?' + @r['QUERY_STRING']})
        [301, @r[:Response], []]
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
    condResponse ->{ self }
  end

  def resourceGET
    paths = justPath.cascade
    [@r.host,""].map{|h|
      paths.map{|p| GET[h+p].do{|fn| fn[self,@r].do{|r| # search for handlers
        return r }}}} # bespoke handler
    response # default handler
  end

  def response
    set = []
    m = {'' => {'uri' => uri, Type => [R[LDP+'Resource']]}}
    rs = ResourceSet[q['set']]
    rs[self,q,m].do{|l|l.map{|r|set.concat r.fileResources}} if rs
    fs = FileSet[q['set']]
    fs[self,q,m].do{|files|set.concat files} if fs
    FileSet[Resource][self,q,m].do{|f|set.concat f} unless rs||fs

    if set.empty?
      if q.has_key? 'new' # skip 404, init blank-resource
        @r[404] = true
      else
        return E404[self,@r,m]
      end
    end
    return @r.SSLupgrade if (q.has_key?('new') || q.has_key?('edit')) && @r.scheme == 'http' # HTTPS required for editing

    @r[:Response].update({ 'Content-Type' => @r.format + '; charset=UTF-8',    # MIME
                           'ETag' => [set.sort.map{|r|[r,r.m]}, @r.format].h}) # representation id
    condResponse ->{ # lazy response-finisher
      if set.size==1 && @r.format == set[0].mime # direct to file
        set[0]
      else
        graph = -> { # load JSON/Hash graph
          set.map{|r|
            r.setEnv(@r).nodeToGraph m} # fs->graph
          @r[:filters].push Container if @r[:container] # summarize contents of container
          @r[:filters].push 'edit' if @r.signedIn && (q.has_key? 'new') || (q.has_key? 'edit')
          @r[:filters].justArray.map{|f|Filter[f].do{|f| f[m,@r] }}
          m }

        if NonRDF.member? @r.format
          Render[@r.format][graph[], @r] # JSON/Hash
        else
          if @r[:container]
            g = graph[].toRDF # summarize
          else # full RDF
            g = RDF::Graph.new
            set.map{|f| f.setEnv(@r).justRDF.do{|doc|g.load doc.pathPOSIX, :base_uri => self}}
          end
          @r[:Response][:Triples] = g.size.to_s
          g.dump (RDF::Writer.for :content_type => @r.format).to_sym,:base_uri => self,:standard_prefixes => true,:prefixes => Prefixes
        end
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
        f = Rack::File.new nil
        f.instance_variable_set '@path', body.pathPOSIX
        f.serving(@r).do{|s,h,b|
          [s, h.update(@r[:Response]), b]}
      else
        [@r[:Status], @r[:Response], [body]]
      end
    end
  end

end
