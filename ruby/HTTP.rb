# coding: utf-8
class R

  def HEAD
    self.GET.do{| s, h, b |[ s, h, []]}
  end

  def setEnv r
    @r = r
    self
  end
  def env; @r end

  def R.call e
    return [405,{},[]] unless %w{HEAD GET}.member? e['REQUEST_METHOD']
    return [404,{},[]] if e['REQUEST_PATH'].match(/\.php$/i)
    e['HTTP_X_FORWARDED_HOST'].do{|h|e['SERVER_NAME']=h}           # find original hostname
    e['SERVER_NAME'] = e['SERVER_NAME'].gsub /[\.\/]+/, '.'        # strip hostname field of gunk
    rawpath = URI.unescape(e['REQUEST_PATH'].utf8).gsub(/\/+/,'/') # path
    path = Pathname.new(rawpath).expand_path.to_s                  # evaluate path-expression
    path += '/' if path[-1] != '/' && rawpath[-1] == '/'           # preserve trailing-slash
    resource = R[e['rack.url_scheme']+"://"+e['SERVER_NAME']+path] # instantiate request object
    e['uri'] = resource.uri # reference normalized URI in environment
    e[:Response] = {}; e[:Links] = {} # response header storage
    (resource.setEnv e).send e['REQUEST_METHOD']
  rescue Exception => x
    msg = [x.class,x.message,x.backtrace].join "\n"
    puts msg
    [500,{'Content-Type' => 'text/plain'},[msg]]
  end

  def notfound
    [404,{'Content-Type' => 'text/html'},[HTML[{},self]]]
  end

  def fileGET
    @r[:Response].update({'Content-Type' => mime, 'ETag' => [m,size].join.sha1})
    @r[:Response].update({'Cache-Control' => 'no-transform'}) if mime.match /^(audio|image|video)/
    condResponse
  end

=begin
  GET['thumbnail'] = -> e {
    thumb = nil
    path = e.path.sub /^.thumbnail/, ''
    i = R['//' + e.host + path]
    i = R[path] unless i.file? && i.size > 0
    if i.file? && i.size > 0
      if i.ext.match /SVG/i
        thumb = i
      else
        thumb = i.dir.child '.' + i.basename + '.png'
        if !thumb.e
          if i.mime.match(/^video/)
            `ffmpegthumbnailer -s 360 -i #{i.sh} -o #{thumb.sh}`
          else
            `gm convert #{i.ext.match(/^jpg/) ? 'jpg:' : ''}#{i.sh} -thumbnail "360x360" #{thumb.sh}`
          end
        end
      end
      thumb && thumb.e && thumb.setEnv(e.env).fileGET || e.notfound
    else
      e.notfound
    end}
=end

  def GET
    return justPath.fileGET if justPath.file? # static response
    return [303,@r[:Response].update({'Location'=> Time.now.strftime('/%Y/%m/%d/%H/')}),[]] if path=='/' # go to now
    set = nodeset
    return notfound if !set || set.empty? # not found
    
    @r[:Response].update({'Link' => @r[:Links].map{|type,uri|"<#{uri}>; rel=#{type}"}.intersperse(', ').join}) unless @r[:Links].empty?
    @r[:Response].update({'Content-Type' => format, 'ETag' => [set.sort.map{|r|[r,r.m]}, format].join.sha1})

    condResponse ->{ # body closure uncalled on HEAD or cache hit
      if set.size==1 && set[0].mime == format
        set[0] # static response
      else # compile response
        if format == 'text/html' # graph in tree for custom renderer. optional, delete for RDF::RDFa handler
          rdf, nonRDF = set.partition &:isRDF # partition set on RDFness
          g = {}                              # JSON tree
          graph = RDF::Graph.new              # RDF graph
          # load (RDF)
          rdf.map{|n|graph.load n.pathPOSIX, :base_uri => uri}
          graph.each_triple{|s,p,o| s = s.to_s;  p = p.to_s
            g[s] ||= {'uri' => s}; g[s][p] ||= []
            g[s][p].push [RDF::Node, RDF::URI].member?(o.class) ? R(o) : o.value}
          # load (non-RDF)
          nonRDF.map{|n| # load JSON tree
            (JSON.parse n.toJSON.readFile).map{|s,re| # walk tree
              re.map{|p,o|
                unless p == 'uri'
                  o.justArray.map{|o|# triple(s) found
                    g[s] ||= {'uri' => s}
                    g[s][p] ||= []
                    g[s][p].push o}
                end}}}
          HTML[g,self] # render
        else # RDF response
          graph = RDF::Graph.new
          set.map{|n| graph.load n.toRDF.pathPOSIX, :base_uri => uri} # load
          graph.dump (RDF::Writer.for :content_type => format).to_sym, :base_uri => uri, :standard_prefixes => true # render
        end
      end}
  end

  def condResponse body=nil
    body ||= -> {self}
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

  def nodeset # fs nodes to include in response
    query = env['QUERY_STRING']
    qs = query && !query.empty? && ('?' + query) || ''
    paths = [self, justPath].uniq
    locs = paths.select &:exist?

    # next+prev month/day/year/hour refs
    dp = []
    parts = path[1..-1].split '/'
    while parts[0] && parts[0].match(/^[0-9]+$/) do
      dp.push parts.shift.to_i
    end
    n = nil; p = nil # next + prev pointers
    case dp.length
    when 1 # Y
      year = dp[0]
      n = '/' + (year + 1).to_s
      p = '/' + (year - 1).to_s
    when 2 # Y-m
      year = dp[0]
      m = dp[1]
      n = m >= 12 ? "/#{year + 1}/#{01}/" : "/#{year}/#{'%02d' % (m + 1)}/"
      p = m <=  1 ? "/#{year - 1}/#{12}/" : "/#{year}/#{'%02d' % (m - 1)}/"
    when 3 # Y-m-d
      day = ::Date.parse "#{dp[0]}-#{dp[1]}-#{dp[2]}" rescue Time.now
      p = (day-1).strftime('/%Y/%m/%d/')
      n = (day+1).strftime('/%Y/%m/%d/')
    when 4 # Y-m-d-H
      day = ::Date.parse "#{dp[0]}-#{dp[1]}-#{dp[2]}" rescue Time.now
      hour = dp[3]
      p = hour <=  0 ? (day - 1).strftime('/%Y/%m/%d/23/') : (day.strftime('/%Y/%m/%d/')+('%02d/' % (hour-1)))
      n = hour >= 23 ? (day + 1).strftime('/%Y/%m/%d/00/') : (day.strftime('/%Y/%m/%d/')+('%02d/' % (hour+1)))
    end
    env[:Links][:prev] = p + parts.join('/') + qs if p && (R['//' + host + p].e || R[p].e)
    env[:Links][:next] = n + parts.join('/') + qs if n && (R['//' + host + n].e || R[n].e)
    
    if q.has_key? 'find' # match names
      query = q['find']
      expression = '-iregex ' + ('.*' + query + '.*').sh
      size = q['min_sizeM'].do{|s| s.match(/^\d+$/) && '-size +' + s + 'M'} || ""
      freshness = q['max_days'].do{|d| d.match(/^\d+$/) && '-ctime -' + d } || ""
      locs.map{|loc|
        `find #{loc.sh} #{freshness} #{size} #{expression} | head -n 255`.lines.map{|l|R.unPOSIX l.chomp}}.flatten
    elsif q.has_key? 'q' # match content
      locs.map{|loc|
        `grep -ril #{q['q'].gsub(' ','.*').sh} #{loc.sh} | head -n 255`.lines.map{|r|R.unPOSIX r.chomp}}.flatten
    elsif q.has_key? 'walk' # tree walk
      count = (q['c'].do{|c|c.to_i} || 12) + 1
      count = 1024 if count > 1024
      # at least 1 result plus lookahead-node startpoint of next page
      count = 2 if count < 2
      orient = q.has_key?('asc') ? :asc : :desc
      ((exist? ? self : justPath).node.take count, orient, q['offset'].do{|o|o.R}).map(&:R).do{|s| # search
        if q['offset'] && head = s[0] # direction-reversal link
          env[:Links][:prev] = path + "?walk&c=#{count-1}&#{orient == :asc ? 'de' : 'a'}sc&offset=" + (URI.escape head.uri)
        end
        if edge = s.size >= count && s.pop # lookahead node at next-page start
          env[:Links][:next] = path + "?walk&c=#{count-1}&#{orient}&offset=" + (URI.escape edge.uri)
        end
        s }
    else
      [self,justPath].uniq.map{|base|base.a('*').glob}.flatten
    end
  end
  
  def readFile; File.open(pathPOSIX).read end

  def appendFile line
    dir.mkdir
    File.open(pathPOSIX,'a'){|f|f.write line + "\n"}
    self
  end

  def writeFile o
    dir.mkdir
    File.open(pathPOSIX,'w'){|f|f << o}
    self
  end

  def mkdir
    FileUtils.mkdir_p(pathPOSIX) unless exist?
    self
  end

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

  def format; @format ||= selectFormat end

  def selectFormat
    { '.html' => 'text/html',
      '.json' => 'application/json',
      '.ttl' => 'text/turtle'}[File.extname(env['REQUEST_PATH'])].do{|m|return m} # URI suffix mapping
    accept.sort.reverse.map{|q,formats|
      formats.map{|mime|
        return mime if RDF::Writer.for(:content_type => mime)}} # renderer found
    'text/html'
  end
  
  end
