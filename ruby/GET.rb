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
    m = {'' => {'uri' => uri, # <> you are here
                Type => [R[LDP+'Resource']]}}
    init = q.has_key? 'new'
    edit = q.has_key? 'edit'
    return @r.SSLupgrade if (init||edit) && @r.scheme == 'http' # HTTPS required for user ID required for edits

    set = [] # resources in response
    rs = ResourceSet[q['set']] # generic-resources provider
    rs[self,q,m].do{|l|l.map{|r|set.concat r.fileResources}} if rs
    fs = FileSet[q['set']] # file(s) provider
    fs[self,q,m].do{|files|set.concat files} if fs
    FileSet[Resource][self,q,m].do{|f|set.concat f} unless rs||fs

    if set.empty?
      if init # create resource
        @r[404] = true # just make a note of it..
      else
        return E404[self,@r,m] # not found
      end
    end

    @r[:Response].update({ 'Content-Type' => @r.format + '; charset=UTF-8',    # MIME type
                           'ETag' => [set.sort.map{|r|[r,r.m]}, @r.format].h}) # representation-id

    condResponse ->{ # lazy response-finisher
      if set.size==1 && @r.format == set[0].mime # only one file in response and it's the requested MIME
        set[0] # return file
      else
        graph = -> {
          set.map{|r|r.nodeToGraph m} # load resources
          @r[:filters].push Container if @r[:container] # summarizer hooks
          @r[:filters].push 'edit' if @r.signedIn && (init||edit) # editable tags
          @r[:filters].justArray.map{|f|Filter[f].do{|f| f[m,@r] }} # transform
          m }

        if NonRDF.member? @r.format
          Render[@r.format][graph[], @r] # JSON/Hash
        else
          if @r[:container]
            g = graph[].toRDF # summarize
          else
            g = RDF::Graph.new
            set.map{|f|f.justRDF.do{|doc|g.load doc.pathPOSIX, :base_uri => self}}
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
