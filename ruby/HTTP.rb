# coding: utf-8
class R

  def HEAD
    self.GET.do{| s, h, b |[ s, h, []]}
  end

  def R.call e
    return [405,{},[]] unless %w{HEAD GET}.member? e['REQUEST_METHOD']
    return [404,{},[]] if e['REQUEST_PATH'].match(/\.php$/i)
#    puts (e['HTTP_USER_AGENT']||'') + ' ' + (e['HTTP_ACCEPT']||'')
    e['HTTP_X_FORWARDED_HOST'].do{|h|e['SERVER_NAME']=h}           # find original hostname
    e['SERVER_NAME'] = e['SERVER_NAME'].gsub /[\.\/]+/, '.'        # strip hostname field of gunk
    rawpath = e['REQUEST_PATH'].utf8.gsub /[\/]+/, '/'             # pathname
    path = Pathname.new(rawpath).expand_path.to_s                  # evaluate path-expression
    path += '/' if path[-1] != '/' && rawpath[-1] == '/'           # preserve trailing-slash
    resource = R[e['rack.url_scheme']+"://"+e['SERVER_NAME']+path] # resource instance
    e['uri'] = resource.uri # reference normalized URI in environment
    e[:Response] = {}; e[:Links] = {} # response header storage
    (resource.setEnv e).send e['REQUEST_METHOD']
  rescue Exception => x
    msg = [x.class,x.message,x.backtrace].join "\n"
    puts msg
    [500,{'Content-Type' => 'text/html'},
     ['<html><head><style>',"\nbody {background-color:#222;font-size:1.2em;text-align:center}\npre {text-align:left;display:inline-block;background-color:#000;color:#fff;font-weight:bold;border-radius:.6em;padding:1em}\n.number {color:#0f0;font-weight:normal;font-size:1.1em}\n",'</style></head><body><pre>',
      msg.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;').gsub(/([0-9\.]+)/,'<span class=number>\1</span>'),
     '</pre></body></html>']]
  end

  def notfound
    [404,{'Content-Type' => 'text/html'},[HTML[{},self]]]
  end

  def fileGET
    @r[:Response].update({'Content-Type' => mime, 'ETag' => [m,size].join.sha1})
    @r[:Response].update({'Cache-Control' => 'no-transform'}) if mime.match /^(audio|image|video)/
    if q.has_key?('thumb') && ext.match(/(mp4|mkv|png|jpg)/i)
      thumb = dir.child '.' + basename + '.png'
      if !thumb.e
        if mime.match(/^video/)
          `ffmpegthumbnailer -s 256 -i #{sh} -o #{thumb.sh}`
        else
          `gm convert #{ext.match(/^jpg/) ? 'jpg:' : ''}#{sh} -thumbnail "256x256" #{thumb.sh}`
        end
      end
      thumb.e && thumb.setEnv(env).condResponse || notfound
    else
      condResponse
    end
  end

  def R.load set # RDF and non
    rdf, nonRDF = set.partition &:isRDF # partition nodes on type
    g = {}                              # JSON graph-in-tree
    graph = RDF::Graph.new              # RDF graph
    # RDF
    rdf.map{|n|graph.load n.pathPOSIX, :base_uri => n}
    graph.each_triple{|s,p,o|
      s = s.to_s
      p = p.to_s
      o = [RDF::Node, RDF::URI, R].member?(o.class) ? o.R : o.value
      g[s] ||= {'uri' => s}
      g[s][p] ||= []
      g[s][p].push o unless g[s][p].member? o}
    # non
    nonRDF.map{|n|
      (JSON.parse n.toJSON.readFile).map{|s,re| # walk tree
        re.map{|p,o|
          o.justArray.map{|o| # each triple
            g[s] ||= {'uri' => s}
            g[s][p] ||= []
            g[s][p].push o unless g[s][p].member? o} unless p == 'uri' }}}
    g
  end

  def load set # just RDF
    g = RDF::Graph.new
    set.map{|n| g.load n.toRDF.pathPOSIX, :base_uri => self}
    g
  end

  def GET
    return notfound if path.match /^\/(cache|domain)/ # hide internal storage paths
    return justPath.fileGET if justPath.file?         # static result
    return [303,@r[:Response].update({'Location'=> Time.now.strftime('/%Y/%m/%d/%H/?')+@r['QUERY_STRING']}),[]] if path=='/' # goto current container
    set = nodeset # find nodes
    return notfound if !set || set.empty? # 404
#    puts "found "+set.join(' ')
    @r[:Response].update({'Link' => @r[:Links].map{|type,uri|"<#{uri}>; rel=#{type}"}.intersperse(', ').join}) unless @r[:Links].empty?
    @r[:Response].update({'Content-Type' => format, 'ETag' => [set.sort.map{|r|[r,r.m]}, format].join.sha1})
    condResponse ->{ # body continuation (unless HEAD or 304 response)
      if set.size==1 && set[0].mime == format
        set[0] # static response
      else # dynamic response
        if format == 'text/html' # HTML
          HTML[R.load(set),self] # render <- load
        else # RDF
          load(set).dump (RDF::Writer.for :content_type => format).to_sym, :base_uri => self, :standard_prefixes => true
        end
      end}
  end

  def condResponse body=nil
    etags = @r['HTTP_IF_NONE_MATCH'].do{|m| m.strip.split /\s*,\s*/ }
    if etags && (etags.include? @r[:Response]['ETag'])
      [304, {}, []]
    else
      body = body ? body.call : self
      if body.class == R # file-ref. use Rack::File handler                           but with our headers
        (Rack::File.new nil).serving((Rack::Request.new @r), body.pathPOSIX).do{|s,h,b|[s,h.update(@r[:Response]),b]}
      else
        [(@r[:Status]||200), @r[:Response], [body]]
      end
    end
  end

  def nodeset
    query = env['QUERY_STRING']
    qs = query && !query.empty? && ('?' + query) || ''
    paths = [self, justPath].uniq
    parts = path[1..-1].split '/'
    trailingSlash = uri[-1]=='/'
    container = paths.find{|p|p.node.directory?}
    find = q.has_key? 'find'
    glob = uri.match /\*/
    grep = q.has_key? 'q'

    # month/day/year/hour pagination
    dp = [] # date parts
    dp.push parts.shift.to_i while parts[0] && parts[0].match(/^[0-9]+$/)
    n = nil; p = nil # pointers
    case dp.length
    when 1 # Y
      year = dp[0]
      n = '/' + (year + 1).to_s
      p = '/' + (year - 1).to_s
    when 2 # Y-m
      year = dp[0]
      m = dp[1]
      n = m >= 12 ? "/#{year + 1}/#{01}" : "/#{year}/#{'%02d' % (m + 1)}"
      p = m <=  1 ? "/#{year - 1}/#{12}" : "/#{year}/#{'%02d' % (m - 1)}"
    when 3 # Y-m-d
      day = ::Date.parse "#{dp[0]}-#{dp[1]}-#{dp[2]}" rescue nil
      if day
        p = (day-1).strftime('/%Y/%m/%d')
        n = (day+1).strftime('/%Y/%m/%d')
      end
    when 4 # Y-m-d-H
      day = ::Date.parse "#{dp[0]}-#{dp[1]}-#{dp[2]}" rescue nil
      if day
        hour = dp[3]
        p = hour <=  0 ? (day - 1).strftime('/%Y/%m/%d/23') : (day.strftime('/%Y/%m/%d/')+('%02d' % (hour-1)))
        n = hour >= 23 ? (day + 1).strftime('/%Y/%m/%d/00') : (day.strftime('/%Y/%m/%d/')+('%02d' % (hour+1)))
      end
    end
    # add pointers, but don't point to 404s
    s = (!parts.empty? || uri[-1]=='/') ? '/' : ''
    env[:Links][:prev] = p + s + parts.join('/') + qs if p && (R['//' + host + p].e || R[p].e)
    env[:Links][:next] = n + s + parts.join('/') + qs if n && (R['//' + host + n].e || R[n].e)

    # find nodes
    set = []
    if container && find
      env[:Links][:up] = justPath.dirname + '/' + qs
      expression = '-iregex ' + ('.*' + q['find'] + '.*').sh
      set.concat paths.select(&:exist?).map{|loc|
        `find #{loc.sh} #{expression} | head -n 255`.lines.map{|l|R.unPOSIX l.chomp}}.flatten
    elsif container && grep
      env[:Links][:up] = justPath.dirname + '/' + qs
      set.concat paths.select(&:exist?).map{|loc|
        `grep -ril #{q['q'].gsub(' ','.*').sh} #{loc.sh} | head -n 255`.lines.map{|r|R.unPOSIX r.chomp}}.flatten
    else
      # container
      set.concat paths.map{|p|
        if p.node.directory?
          if trailingSlash
            env[:Links][:up] = path[0..-2] + qs # up to dir summary (no trailing-slash)
            [p, p.children]
          else
            env[:Links][:down] = path + '/' + qs # down to inlined children (trailing-slash)
            p
          end
        end
      }.flatten.compact
      env[:Links][:up] ||= justPath.dirname + '/' + qs # parent
      # docs
      set.concat paths.map{|p|
        pattern = glob ? p : (p.stripSlash + '.*') # bespoke glob or document glob
        pattern.glob
      }.flatten
    end
    set_ = set.select &:exist?
    eaccess = set - set_
    puts "WARNING can't access: "+eaccess.join(' ') unless eaccess.empty?
    set_
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

  def R.qs h # {k: v} -> query-string
    '?'+h.map{|k,v|
      k.to_s + '=' + (v ? (CGI.escape [*v][0].to_s) : '')}.intersperse("&").join('')
  end

  def format; @format ||= selectFormat end

  def selectFormat
    accept.sort.reverse.map{|q,formats|
      formats.map{|mime|
        return mime if RDF::Writer.for(:content_type => mime)}}
    'text/html'
  end
  
  end
