#watch __FILE__
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
      paths.map{|p| GET[h+p].do{|fn| fn[self,@r].do{|r| # search for handlers
        return r }}}} # bespoke handler
    response # default handler
  end

  def response
    init = q.has_key? 'new'
    set = []
    m = {'' => {'uri' => uri, Type => [R[LDP+'Resource']]}}
    s = q['set']
    rs = ResourceSet[s]
    fs = FileSet[s]

    FileSet[Resource][self,q,m].do{|f|set.concat f} unless rs||fs
    fs[self,q,m].do{|files|set.concat files} if fs
    rs[self,q,m].do{|l|l.map{|r|set.concat r.fileResources}} if rs

    return E404[self,@r,m] if set.empty? && !init

    m['#'] ||= {Type => R[q.has_key?('type') ? '#editor' : '#typeSelector']} if init
    @r[:Response].update({ 'Content-Type' => @r.format + '; charset=UTF-8',    # MIME
                           'ETag' => [set.sort.map{|r|[r,r.m]}, @r.format].h}) # representation id
    ldp # capability headers
    condResponse ->{ # lazy response-finish

      if set.size==1 && @r.format == set[0].mime # direct pass-through of file
        set[0]
      else
        graph = -> { set.map{|r|r.setEnv(@r).nodeToGraph m}
          Mutate[m,@r]; m}
        if NonRDF.member? @r.format
          Render[@r.format][graph[], @r]
        else
          if @r[:container]
            g = graph[].toRDF
          else
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
