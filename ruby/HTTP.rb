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
    return [405,{},[]] unless %w{HEAD GET}.member? e['REQUEST_METHOD'] # disallow arbitrary methods. use https://github.com/solid/node-solid-server or similar for PUT/PATCH
    return [404,{},[]] if e['REQUEST_PATH'].match(/\.php$/i) # we don't serve PHP, no need to continue
    e['HTTP_X_FORWARDED_HOST'].do{|h|e['SERVER_NAME']=h}           # unproxy hostname
    e['SERVER_NAME'] = e['SERVER_NAME'].gsub /[\.\/]+/, '.'        # strip hostname field of gunk
    rawpath = URI.unescape(e['REQUEST_PATH'].utf8).gsub(/\/+/,'/') # path
    path = Pathname.new(rawpath).expand_path.to_s                  # evaluate path-expression
    path += '/' if path[-1] != '/' && rawpath[-1] == '/'           # preserve trailing-slash
    resource = R[e['rack.url_scheme']+"://"+e['SERVER_NAME']+path] # instantiate request object
    e['uri'] = resource.uri # bind URI
    e[:Response] = {} # init response header
    e[:Links] = {} # init Link-header map
    resource.setEnv(e).send(e['REQUEST_METHOD']).do{|s,h,b| # run request, bind response for inspection/logging
      # basic request log
      puts [s, resource.uri, h['Location'] ? ['->',h['Location']] : nil, resource.format, e['HTTP_REFERER'], e['HTTP_USER_AGENT']].join ' '
      [s,h,b]} # return unmodified response when done
  rescue Exception => x
    out = [x.class,x.message,x.backtrace].join "\n"
    puts out
    [500,{'Content-Type' => 'text/plain'},[out]]
  end

  def notfound
    @r[404]=true
    [404,{'Content-Type' => format},
     [Render[format].do{|fn|fn[graph,self]} ||
      graph.toRDF(self).dump(RDF::Writer.for(:content_type => format).to_sym)]]
  end

  def GET
    if file?
      fileGET
    elsif justPath.file?
      justPath.fileGET
    else
      # options
      stars = uri.scan('*').size
      @r[:find] = true if q.has_key? 'find'
      @r[:glob] = true if stars > 0 && stars <= 3
      @r[:grep] = true if q.has_key? 'q'
      @r[:walk] = true if q.has_key? 'walk'
      @r[:sort] = q['sort'] || Date

      # find custom handler or default response
      GET[path[1..-1].split('/')[0]].do{|handler| handler[self].do{|r| return r }}
      response
    end
  end

  def fileGET
    @r[:Response].
      update({ 'Content-Type' => mime + '; charset=UTF-8',
               'ETag' => [m,size].join.sha1 })
    @r[:Response].update({'Cache-Control' => 'no-transform'}) if mime.match /^(audio|image|video)/
    condResponse ->{ self }
  end

  def response
    # container requested, enter inlined child-node relative-URI base
    container = node.directory? || justPath.node.directory?
    if container && uri[-1] != '/'
      qs = @r['QUERY_STRING']
      @r[:Response].update({'Location' => @r['REQUEST_PATH'] + '/' + (qs && !qs.empty? && ('?'+qs) || '')})
      return [301, @r[:Response], []]
    end

    set = nodeset
    return notfound if !set || set.empty?

    @r[:Response].update({'Link' => @r[:Links].map{|type,uri|"<#{uri}>; rel=#{type}"}.intersperse(', ').join}) unless @r[:Links].empty?
    @r[:Response].update({'Content-Type' => format,
                          'ETag' => [set.sort.map{|r|[r,r.m]}, format].join.sha1})

    # lazy body-serialize, uncalled on HEAD and ETag hit
    condResponse ->{
      # if set has one file and its MIME won preference
      if set.size==1 && format == set[0].mime
        set[0] # static response
      else # compile response

        # loader lambda
        loadGraph = -> {
          graph = {}
          set.map{|r|r.loadGraph graph}
          unless q.has_key? 'full'
            Summarize[graph,self] if @r[:glob] || container || q.has_key?('abbr')
            Grep[graph,self] if @r[:grep]
          end
          graph}

        if %w{application/atom+xml application/json text/html text/uri-list}.member? format
          # return serialized non-RDF
          Render[format][loadGraph[],self]
        else # RDF format
          base = @r.R.join uri
          if container # summarize contained graph
            g = loadGraph[].toRDF
          else # full RDF graph
            g = RDF::Graph.new
            set.map{|f|
              f.justRDF(%w{e html jsonld n3 nt owl rdf ttl}).do{|doc| # transcode non-RDF
                g.load doc.pathPOSIX, :base_uri => base}} # load RDF
          end
          # return serialized RDF
          g.dump (RDF::Writer.for :content_type => format).to_sym, :base_uri => base, :standard_prefixes => true
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

  def q # memoize query args
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

  def R.qs h # serialize Hash to querystring
    '?'+h.map{|k,v|
      k.to_s + '=' + (v ? (CGI.escape [*v][0].to_s) : '')}.intersperse("&").join('')
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
        return mime if R::Render[mime]||RDF::Writer.for(:content_type => mime)}} # renderer exists
    'text/html' # default
  end

  end
