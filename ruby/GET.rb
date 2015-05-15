# coding: utf-8
#watch __FILE__
class R

  def GET
    ldp
    if file?
      fileGET
    elsif justPath.file?
      justPath.fileGET
    else
      stripDoc.resourceGET
    end
  end

  def fileGET
    @r[:Response].
      update({ 'Content-Type' => mime + '; charset=UTF-8',
               'ETag' => [m,size].h })
    @r[:Response].update({'Cache-Control' => 'no-transform'}) if mime.match /^(audio|image|video)/
    condResponse ->{ self }
  end

  def resourceGET # custom-handler lookup
    paths = justPath.cascade 
    [@r.host,""].map{|h| # host-specific, then daemon-wide
      paths.map{|p| # bubble up to /
        GET[h+p].do{|fn| # handler found
          fn[self,@r].do{|r| # call handler
        return r }}}} # return (a non-nil handler response)
    response # default response
  end

  def response
    if directory?
      if uri[-1] == '/'
        @r[:container] = true
      else # redirect to enter container
        qs = @r['QUERY_STRING']
        @r[:Response].update({'Location' => uri + '/' + (qs && !qs.empty? && ('?' + qs) || '')})
        return [301, @r[:Response], []]
      end
    end

    init = q.has_key? 'new'
    edit = q.has_key? 'edit'
    return @r.SSLupgrade if (init||edit) && @r.scheme == 'http' # HTTPS required for editing

    m = {} # graph
    set = [] # resource-set

    # generic-resource set
    rs = ResourceSet[q['set']]
    rs[self,q,m].do{|l|l.map{|r|set.concat r.fileResources}} if rs

    # file set
    fs = FileSet[q['set']]
    fs[self,q,m].do{|files|set.concat files} if fs

    # default set
    FileSet[Resource][self,q,m].do{|f|set.concat f} unless rs||fs

    if set.empty? # empty set
      @r[404] = true
      return E404[self,@r,m] unless init
    end

    @r[:Response].
      update({'Content-Type' => @r.format + '; charset=UTF-8',
              'Link' => @r[:Links].map{|type,uri|"<#{uri}>; rel=#{type}"}.intersperse(', ').join,
              'ETag' => [set.sort.map{|r|[r,r.m]}, @r.format].h})

    condResponse ->{ # lazy response-finisher
      if set.size==1 && @r.format == set[0].mime # one file in response, MIME in Accept
        set[0] # no transcode, just return file
      else
        graph = -> { # JSON/Hash model construction
          set.map{|r|r.nodeToGraph m} # load resources
          @r[:filters].push Container if @r[:container] # add summarizer for container
          @r[:filters].push 'edit' if @r.signedIn && (init||edit) # add editor-facilities
          @r[:filters].justArray.map{|f|Filter[f].do{|f| f[m,@r] }} # do arbitrary-transforms
          m } # model

        if NonRDF.member? @r.format
          Render[@r.format][graph[],@r]
        else # RDF
          if @r[:container] # container
            g = graph[].toRDF
          else # doc
            g = RDF::Graph.new
            set.map{|f|f.justRDF.do{|doc|g.load doc.pathPOSIX, :base_uri => self}}
          end
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

  # get from underlying FS
  def readFile parseJSON=false
    if f
      if parseJSON
        begin
          JSON.parse File.open(pathPOSIX).read
        rescue Exception => x
          puts "error reading JSON: #{caller} #{uri} #{x}"
          {}
        end
      else
        File.open(pathPOSIX).read
      end
    else
      nil
    end
  end
  alias_method :r, :readFile

end
