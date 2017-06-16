# coding: utf-8
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
  def env; @r end

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
    [404,{'Content-Type' => format},[]]
  end

  def GET
    if justPath.file?
      justPath.fileGET
    else

      # options
      stars = uri.scan('*').size
      @r[:find] = true if q.has_key? 'find'
      @r[:glob] = true if stars > 0 && stars <= 3
      @r[:grep] = true if q.has_key? 'q'
      @r[:walk] = true if q.has_key? 'walk'
      @r[:sort] = q['sort'] || Date

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

  def response
    # enter container/ so we can include children with relative URIs
    container = node.directory? || justPath.node.directory?
    if container && uri[-1] != '/'
      qs = @r['QUERY_STRING']
      @r[:Response].update({'Location' => @r['REQUEST_PATH'] + '/' + (qs && !qs.empty? && ('?'+qs) || '')})
      return [301, @r[:Response], []]
    end

    # find data
    set = nodeset
    return notfound if !set || set.empty?

    # response metadata
    @r[:Response].update({'Link' => @r[:Links].map{|type,uri|"<#{uri}>; rel=#{type}"}.intersperse(', ').join}) unless @r[:Links].empty?
    @r[:Response].update({'Content-Type' => format,
                          'ETag' => [set.sort.map{|r|[r,r.m]}, format].join.sha1})

    # lazy body-serialize, uncalled on HEAD and client-side cache hit via ETag match
    condResponse ->{
      if set.size==1 && set[0].mime == format
        set[0] # static response
      else # compile response
        puts set.join " "
        base = @r.R.join uri
        graph = RDF::Graph.new
        # gather document graphs
        set.map{|file|
          if file.file?
            if RDF::Reader.for :content_type => file.mime
              puts "load RDF #{file}"
              graph.load file.pathPOSIX, :base_uri => base
            else
              puts "no reader for #{file} type #{file.mime}"
            end
          else
            puts "not a file: #{file}"
          end
        }
        # output
        if format=='text/html'
          g = {}
          puts "Render HTML"
          graph.each_triple{|s,p,o|puts s,p,o}
          "HHHTML"
        elsif writer = (RDF::Writer.for :content_type => format)
          graph.dump writer.to_sym, :base_uri => base, :standard_prefixes => true
        else
          "no writer for #{format}"
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

  # find file-system nodes for response
  def nodeset
    query = env['QUERY_STRING']
    qs = query && !query.empty? && ('?' + query) || ''
    paths = [self, justPath].uniq
    locs = paths.select &:exist?

    # add next+prev month/day/year/hour pointers to header
    dp = []
    parts = stripHost[1..-1].gsub('#','%23').split '/'
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
    
    if env[:find] # match names
      query = q['find']
      expression = '-iregex ' + ('.*' + query + '.*').sh
      size = q['min_sizeM'].do{|s| s.match(/^\d+$/) && '-size +' + s + 'M'} || ""
      freshness = q['max_days'].do{|d| d.match(/^\d+$/) && '-ctime -' + d } || ""
      locs.map{|loc|
        `find #{loc.sh} #{freshness} #{size} #{expression} | head -n 255`.lines.map{|l|R.unPOSIX l.chomp}}.flatten
    elsif env[:grep] # match content
      locs.map{|loc|
        `grep -ril #{q['q'].gsub(' ','.*').sh} #{loc.sh} | head -n 255`.lines.map{|r|R.unPOSIX r.chomp}}.flatten
    elsif env[:walk] # tree walk
      count = (q['c'].do{|c|c.to_i} || 12) + 1
      count = 1024 if count > 1024
      # at least 1 result plus lookahead-node startpoint of next page
      count = 2 if count < 2
      orient = q.has_key?('asc') ? :asc : :desc
      ((exist? ? self : justPath).take count, orient, q['offset'].do{|o|o.R}).do{|s| # search
        if q['offset'] && head = s[0] # direction-reversal link
          env[:Links][:prev] = path + "?walk&c=#{count-1}&#{orient == :asc ? 'de' : 'a'}sc&offset=" + (URI.escape head.uri)
        end
        if edge = s.size >= count && s.pop # lookahead node at next-page start
          env[:Links][:next] = path + "?walk&c=#{count-1}&#{orient}&offset=" + (URI.escape edge.uri)
        end
        s }
    else
      [self,justPath].uniq.map{|base|base.a('.*').glob}.flatten      
    end
  end
  
  def readFile
    File.open(pathPOSIX).read if f
  end

  def appendFile line
    dir.mk
    File.open(pathPOSIX,'a'){|f|f.write line + "\n"}
  end

  def writeFile o
    dir.mk
    File.open(pathPOSIX,'w'){|f|f << o}
    self
  end

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

  def format; @format ||= selectFormat end

  def selectFormat
    { '.html' => 'text/html',
      '.json' => 'application/json',
      '.ttl' => 'text/turtle'}[File.extname(env['REQUEST_PATH'])].do{|m|return m} # URI suffix mapping
    accept.sort.reverse.map{|q,formats|
      formats.map{|mime|
        return mime if R::Render[mime] || RDF::Writer.for(:content_type => mime)}} # renderer found
    'text/html'
  end
  
  end
