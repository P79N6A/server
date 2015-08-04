# coding: utf-8
#watch __FILE__
class R

  def GET
    ldp
    if file? && !q.has_key?('data')
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

  def resourceGET # handler lookup
    bases = [@r.host, ""] # specific host, then generic path
    paths = justPath.cascade.map(&:to_s).map &:downcase
    bases.map{|b|
      paths.map{|p|
        GET[b + p].do{|fn| # handler bound
          fn[self,@r].do{|r| # call
        return r }}}} # non-nil return, stop cascading and finish
    response
  end

  def response # default GET request->response handler
    init = q.has_key? 'new'
    edit = q.has_key? 'edit'
    return @r.SSLupgrade if (init||edit) && @r.scheme == 'http' # HTTPS required when editing

    if directory?
      if uri[-1] == '/' # in the container
        @r[:container] = true
      else # enter container
        qs = @r['QUERY_STRING']
        @r[:Response].update({'Location' => uri + '/' + (qs && !qs.empty? && ('?' + qs) || '')})
        return [301, @r[:Response], []]
      end
    end

    set = []
    graph = {}

    # find generic-resource(s)
    rs = ResourceSet[q['set']]
    rs[self,q,graph].do{|l|l.map{|r|set.concat r.fileResources}} if rs

    # find file(s)
    fs = FileSet[q['set']]
    fs[self,q,graph].do{|files|set.concat files} if fs

    FileSet[Resource][self,q,graph].do{|f|set.concat f} unless rs||fs

    if set.empty?
      @r[404] = true
      return E404[self,@r,graph] unless init
    end

    @r[:Response].
      update({'Content-Type' => @r.format + '; charset=UTF-8',
              'Link' => @r[:Links].map{|type,uri|"<#{uri}>; rel=#{type}"}.intersperse(', ').join,
              'ETag' => [set.sort.map{|r|[r,r.m]}, @r.format].h})

    condResponse ->{ # lazy response-finisher
      if set.size==1 && @r.format == set[0].mime # one file in response, MIME preferred
        set[0] # no transcode, just return file
      else
        loadGraph = -> {
          set.map{|r|r.nodeToGraph graph} # load resources
          @r[:filters].push Container if @r[:container] # container-summarize
          @r[:filters].push '#create' if @r.signedIn && init # create a resource

          @r[:filters].justArray.map{|f|
            Filter[f][graph,@r]} # transform
          graph}

        if NonRDF.member? @r.format
          Render[@r.format][loadGraph[],@r]
        else
          base = @r.R.join uri
          if @r[:container] # container
            g = loadGraph[].toRDF
          else # doc
            g = RDF::Graph.new
            set.map{|f|f.justRDF.do{|doc|g.load doc.pathPOSIX, :base_uri => base}}
          end
          g.dump (RDF::Writer.for :content_type => @r.format).to_sym, :base_uri => base, :standard_prefixes => true,:prefixes => Prefixes
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

  # get content from underlying FS
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
