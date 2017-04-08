# coding: utf-8

module Rack
  module Adapter
    # load this config so "config.ru" file doesnt need to exist
    def self.guess _; :rack end
    def self.load _
      Rack::Builder.new {
        use Rack::Deflater # gzip response
        run R              # call R.call
      }.to_app
    end
  end
end

class R

  AllowMethods = %w{HEAD GET}
  Allow = AllowMethods.join ', '

  def HEAD
    self.GET.
    do{| s, h, b |
       [ s, h, []]}
  end

  def setEnv r
    @r = r
    self
  end

  def env
    @r
  end

  def R.call e
    return [405,{'Allow' => Allow},[]] unless AllowMethods.member? e['REQUEST_METHOD'] # disallow arbitrary methods
    return [404,{},[]] if e['REQUEST_PATH'].match(/\.php$/i) # 404 requests for PHP

    e['HTTP_X_FORWARDED_HOST'].do{|h|e['SERVER_NAME']=h}     # use requested hostname
    e['SERVER_NAME'] = e['SERVER_NAME'].gsub /[\.\/]+/, '.'  # strip hostname field
    rawpath = URI.unescape(e['REQUEST_PATH'].utf8).gsub(/\/+/,'/') # pathnames can contain URI special-chars
    path = Pathname.new(rawpath).expand_path.to_s # evaluate path expression
    path += '/' if path[-1] != '/' && rawpath[-1] == '/' # preserve trailing-slash if necessary
    resource = R[e['rack.url_scheme'] + "://" + e['SERVER_NAME'] + path] # final requested-resource

    e['uri'] = resource.uri # bind URI attribute to environment
    e[:Response] = {} # init response-header fields
    e[:Links] = {} # init Link header map

    #    e.map{|k,v|puts k.to_s + "\t" + v.to_s}

    resource.setEnv(e).send(e['REQUEST_METHOD']).do{|s,h,b| # run request, inspecting response
      puts [s, resource.uri, h['Location'] ? ['->',h['Location']] : nil, resource.format, e['HTTP_REFERER'], e['HTTP_USER_AGENT']].join ' '

#      h.map{|k,v|puts k.to_s + "\t" + v.to_s}

      [s,h,b]} # return
  rescue Exception => x
    out = [x.class,x.message,x.backtrace].join "\n"
    puts out
    [500,{'Content-Type' => 'text/plain'},[out]]
  end

  def notfound
    [404,{'Content-Type' => format},
     [Render[format].do{|fn|fn[graph,self]} ||
      graph.toRDF(self).dump(RDF::Writer.for(:content_type => format).to_sym)]]
  end

  def GET
    if file? # host-specific path
      fileGET
    elsif justPath.file? # path on any host
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

  def resourceGET
    bases = [host, ""] # host, path
    paths = justPath.cascade.map(&:to_s).map &:downcase
    bases.map{|b|
      paths.map{|p| # bubble up to root
        GET[b + p].do{|fn| # bind
          fn[self].do{|r| # call
        return r }}}} # found handler, terminate search
    response
  end

  def response

    # support graph filter and file-set patterns
    stars = uri.scan('*').size
    @r[:glob] = true if stars > 0 && stars <= 3
    @r[:grep] = true if q.has_key?('q') && q['set'] != 'find'

    # enforce trailing-slash as we allow relative-URIs and inline child-nodes
    container = directory?
    if container && uri[-1] != '/'
      qs = @r['QUERY_STRING']
      @r[:Response].update({'Location' => uri + '/' + (qs && !qs.empty? && ('?' + qs) || '')})
      return [301, @r[:Response], []]
    end

    # search for resource set
    set = []
    (Set[q['set']]||Set[Resource])[self].do{|f|
      set.concat f}
    return notfound if set.empty?

    # set response-head values
    @r[:Response].update({'Link' => @r[:Links].map{|type,uri|"<#{uri}>; rel=#{type}"}.intersperse(', ').join}) unless @r[:Links].empty?
    @r[:Response].update({'Content-Type' => format,
                          'ETag' => [set.sort.map{|r|[r,r.m]}, format].h})

    # lazy body-serialize, uncalled on HEAD and ETag hit
    condResponse ->{
      # if set has one file and its MIME is preferred
      if set.size==1 && format == set[0].mime
        set[0] # return file handle
      else

        loadGraph = -> { # graph loader
          graph = {}
          set.map{|r|r.loadGraph graph}
          unless q.has_key? 'full'
            Summarize[graph,self] if @r[:glob] || container || q.has_key?('abbr')
            Grep[graph,self] if @r[:grep]
          end
          graph}

        if NonRDF.member? format
          # return serialized non-RDF
          Render[format][loadGraph[],self]
        else
          base = @r.R.join uri
          if container # call lambda for summarized graph
            g = loadGraph[].toRDF
          else # full RDF graph
            g = RDF::Graph.new
            set.map{|f|f.justRDF.do{|doc|g.load doc.pathPOSIX, :base_uri => base}}
          end
          # return serialized RDF
          g.dump (RDF::Writer.for :content_type => format).to_sym, :base_uri => base, :standard_prefixes => true,:prefixes => Prefixes
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
        (Rack::File.new nil).serving((Rack::Request.new @r),body.pathPOSIX).do{|s,h,b|
          [s, h.update(@r[:Response]), b]}
      else
        [@r[:Status], @r[:Response], [body]]
      end
    end
  end

  def readFile parseJSON=false
    if f
      if parseJSON
        JSON.parse File.open(pathPOSIX).read
      else
        File.open(pathPOSIX).read
      end
    else
      nil
    end
  rescue
    nil
  end
  alias_method :r, :readFile

  def delete; node.deleteNode if e; self end

  def appendFile line
    dir.mk
    File.open(pathPOSIX,'a'){|f|f.write line + "\n"}
  end

  def writeFile o,s=false
    dir.mk
    File.open(pathPOSIX,'w'){|f|
      f << (s ? o.to_json : o)}
    self
  end
  alias_method :w, :writeFile

  def mkdir
    e || FileUtils.mkdir_p(pathPOSIX)
    self
  end
  alias_method :mk, :mkdir

  def accept
    @accept ||= (
      d={}
      env['HTTP_ACCEPT'].do{|k|
        (k.split /,/).map{|e| # each pair
          f,q = e.split /;/   # split MIME from q value
          i = q && q.split(/=/)[1].to_f || 1.0 # q || default
          d[i] ||= []; d[i].push f.strip}} # append
      d)
  end

  def selector
    @idCount ||= 0
    'O' + (@idCount += 1).to_s
  end

  def q # memoize key/vals
    @q ||=
      (if q = env['QUERY_STRING']
       h = {}
       q.split(/&/).map{|e|
         k, v = e.split(/=/,2).map{|x|CGI.unescape x}
         h[(k||'').downcase] = v}
       h
      else
        {}
       end)
  end

  def format # memoized MIME
    @format ||= selectFormat
  end

  def selectFormat
    # explicit URI suffix
    { '.html' => 'text/html', '.json' => 'application/json', '.ttl' => 'text/turtle',
    }[File.extname(env['REQUEST_PATH'])].do{|m|return m}
    # environment (request header-fields)
    accept.sort.reverse.map{|q,mimes| # highest Qval bound first
      # if multiple MIMEs remain, tiebreak
      mimes.sort_by{|m|{'text/html' => 0, 'text/turtle' => 1}[m]||2}.map{|mime|
        return mime if R::Render[mime]||RDF::Writer.for(:content_type => mime)}} # native or RDF-library renderer exists
    'text/html' # default
  end

  end

class Hash
  def qs # serialize to query-string
    '?'+map{|k,v|
      k.to_s + '=' + (v ? (CGI.escape [*v][0].to_s) : '')
    }.intersperse("&").join('')
  end
end


class Pathname

  def deleteNode
    FileUtils.send (file?||symlink?) ? :rm : :rmdir, self
    parent.deleteNode if parent.c.empty? # parent now empty, delete it
  end

end
