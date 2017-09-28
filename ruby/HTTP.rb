# coding: utf-8
class R

  def R.call e
    return [405,{},[]] unless %w{HEAD GET}.member? e['REQUEST_METHOD']
    return [404,{},[]] if e['REQUEST_PATH'].match(/\.php$/i)
    rawpath = e['REQUEST_PATH'].utf8.gsub /[\/]+/, '/'   # collapse sequential /s
    path = Pathname.new(rawpath).expand_path.to_s        # evaluate path
    path += '/' if path[-1] != '/' && rawpath[-1] == '/' # preserve trailing-slash
    resource = path.R; e['uri'] = resource.uri           # resource URI
    e[:Response]={}; e[:Links]={}                        # response header
#    puts e['HTTP_USER_AGENT']
    resource.setEnv(e).send e['REQUEST_METHOD']          # call method
  rescue Exception => x
    msg = [x.class,x.message,x.backtrace].join "\n"
    [500,{'Content-Type' => 'text/html'},
     ["<html><head><style>body {background-color:#222; font-size:1.2em; text-align:center}\npre {text-align:left; display:inline-block; background-color:#000; color:#fff; font-weight:bold; border-radius:.6em; padding:1em}\n.number {color:#0f0; font-weight:normal; font-size:1.1em}</style></head><body><pre>",
      msg.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;').gsub(/([0-9\.]+)/,'<span class=number>\1</span>'),
      '</pre></body></html>']]
  end

  def HEAD; self.GET.do{|s,h,b|[s,h,[]]} end

  def timeRegion
    time = Time.now
    puts path,path.class
    loc = time.strftime(case path[1]
                        when 'y'
                          '/%Y/'
                        when 'm'
                          '/%Y/%m/'
                        when 'd'
                          '/%Y/%m/%d/'
                        when 'h'
                          '/%Y/%m/%d/%H/'
                        else
                        end)
    [303,
     @r[:Response].update({'Location'=> loc + (qs.empty? ? '?head' : qs)}),[]]
  end

  def feed
    [303,
     @r[:Response].update({'Location'=> Time.now.strftime('/%Y/%m/%d/%H/?feed')}),[]]
  end

  def GET
    return file if file?
    return feed if path == '/feed'
    return timeRegion if path.match(/^\/(y(ear)?|m(onth)?|d(ay)?|h(our)?)$/)

    # time pointers
    parts = path[1..-1].split '/'
    dp = []; dp.push parts.shift.to_i while parts[0] && parts[0].match(/^[0-9]+$/)
    n = nil; p = nil
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
    sl = parts.empty? ? '' : (path[-1] == '/' ? '/' : '')

    @r[:Links][:prev] = p + '/' + parts.join('/') + sl + qs if p && R[p].e
    @r[:Links][:next] = n + '/' + parts.join('/') + sl + qs if n && R[n].e
    @r[:Links][:up] = dirname + (dirname == '/' ? '' : '/') + qs

    # find loadable-resource nodes
    set = (if node.directory?
           if (q.has_key? 'find') && path!='/' # FIND(1) nodes
             find q['find']
           elsif (q.has_key? 'q') && path!='/' # GREP(1) nodes
             grep q['q']
           else # basic container
             if uri[-1] == '/' # inside container
               if q.has_key? 'head' # summary view
                 q_ = q.dup; q_.delete 'head' # link to full full view
                 @r[:Links][:down] = path + R.qs(q_) # down to children
               end
               (self+'index.*').glob || [self, children] # inlined children
             else # outside container
               @r[:Links][:down] = path + '/' + qs # down to children
               self # just the container
             end
           end
          else # arbitrary or extension-wildcard glob
            (match(/\*/) ? self : (self+'.*')).glob
           end).justArray.flatten.compact.select &:exist?

    return notfound if !set || set.empty?

    @r[:Response].update({'Link' => @r[:Links].map{|type,uri|"<#{uri}>; rel=#{type}"}.intersperse(', ').join}) unless @r[:Links].empty?
    @r[:Response].update({'Content-Type' => format, 'ETag' => [set.sort.map{|r|[r,r.m]}, format].join.sha2})
    condResponse ->{ # body
      if set.size == 1 && set[0].mime == format
        set[0] # static body
      else # dynamic body
        if format == 'text/html'
          HTML[R.load(set),self]
        elsif format == 'application/atom+xml'
          FEED[R.load(set),self]
        else
          load(set).dump (RDF::Writer.for :content_type => format).to_sym, :base_uri => self, :standard_prefixes => true
        end
      end}
  end

  def grep q
    words = R.tokens q
    case words.size # unordered && (AND) terms
    when 2
      cmd = "grep -rilZ #{words[0].sh} #{sh} | xargs -0 grep -il #{words[1].sh}"
    when 3
      cmd = "grep -rilZ #{words[0].sh} #{sh} | xargs -0 grep -ilZ #{words[1].sh} | xargs -0 grep -il #{words[2].sh}"
    when 4
      cmd = "grep -rilZ #{words[0].sh} #{sh} | xargs -0 grep -ilZ #{words[1].sh} | xargs -0 grep -ilZ #{words[2].sh} | xargs -0 grep -il #{words[3].sh}"
    else # terms in submitted order
      pattern = words.join '.*'
      cmd = "grep -ril #{pattern.sh} #{sh}"
    end
    `#{cmd} | head -n 1024`.lines.map{|matchingFile| R.fromPOSIX matchingFile.chomp}
  end

  # JSON loader
  def R.load set
    graph = RDF::Graph.new # input graph
    g = {}                 # output tree
    rdf,nonRDF = set.partition &:isRDF # partition node types
    # load RDF formats
    rdf.map{|n|graph.load n.pathPOSIX, :base_uri => n}
    # RDF triples to tree
    graph.each_triple{|s,p,o| # each triple
      s = s.to_s; p = p.to_s # subject/predicate URI keys
      o = [RDF::Node, RDF::URI, R].member?(o.class) ? o.R : o.value # normalize resource classes
      g[s]||={'uri'=>s}; g[s][p]||=[]; g[s][p].push o unless g[s][p].member? o} # add
    # load JSON format
    nonRDF.map{|n| (JSON.parse n.toJSON.readFile).map{|s,re| # each subject
        re.map{|p,o| # each predicate/object
          o.justArray.map{|o| # each triple
            o = o.R if o.class==Hash # normalize resource classes
            g[s]||={'uri'=>s}; g[s][p]||=[]; g[s][p].push o unless g[s][p].member? o} unless p == 'uri' }}} # add
    g # tree-graph
  end

  # RDF loader
  def load set
    g = RDF::Graph.new
    set.map{|n|
      g.load n.toRDF.pathPOSIX, :base_uri => n.stripDoc}
    g # RDF graph
  end


  def file
    @r[:Response].update({'Content-Type' => mime, 'ETag' => [m,size].join.sha2})
    @r[:Response].update({'Cache-Control' => 'no-transform'}) if mime.match /^(audio|image|video)/
    if q.has_key?('thumb') && ext.match(/(mp4|mkv|png|jpg)/i)
      if !thumb.e
        if mime.match(/^video/)
          `ffmpegthumbnailer -s 256 -i #{sh} -o #{thumb.sh}`
        else
          `gm convert #{sh} -thumbnail "256x256" #{thumb.sh}`
        end
      end
      thumb.e && thumb.setEnv(@r).condResponse || notfound
    else
      condResponse
    end
  end

  def condResponse body=nil
    etags = @r['HTTP_IF_NONE_MATCH'].do{|m| m.strip.split /\s*,\s*/ }
    if etags && (etags.include? @r[:Response]['ETag'])
      [304, {}, []]
    else
      body = body ? body.call : self
      if body.class == R # file-ref. use Rack::File handler                                       add our headers
        (Rack::File.new nil).serving((Rack::Request.new @r), body.pathPOSIX).do{|s,h,b|[s,h.update(@r[:Response]),b]}
      else
        [(@r[:Status]||200), @r[:Response], [body]]
      end
    end
  end

  def notfound
    [404,{'Content-Type' => 'text/html'},[HTML[{},self]]]
  end

  def accept
    @accept ||= (
      d={}
      @r['HTTP_ACCEPT'].do{|k|
        (k.split /,/).map{|e| # each pair
          f,q = e.split /;/   # split MIME from q value
          i = q && q.split(/=/)[1].to_f || 1.0 # q || default
          d[i] ||= []; d[i].push f.strip}} # append
      d)
  end

  def q # query-args hashmap
    @q ||=
      (if q = @r['QUERY_STRING']
       h = {}
       q.split(/&/).map{|e|
         k, v = e.split(/=/,2).map{|x|CGI.unescape x}
         h[(k||'').downcase] = v}
       h
      else
        {}
       end)
  end

  def qs # query-string
    @qs ||= (@r['QUERY_STRING'] && !@r['QUERY_STRING'].empty? && ('?' + @r['QUERY_STRING']) || '')
  end

  def R.qs h # query-args hashmap -> query-string
    '?'+h.map{|k,v|
      k.to_s + '=' + (v ? (CGI.escape [*v][0].to_s) : '')}.intersperse("&").join('')
  end

  def format; @format ||= selectFormat end

  def selectFormat
    # query-string arg
    return 'application/atom+xml' if q.has_key?('feed')

    # Accept header
    accept.sort.reverse.map{|q,formats| # highest qval first
      formats.map{|mime| # serializability check
        return mime if RDF::Writer.for(:content_type => mime) || Writable.member?(mime)}}

    # default
    'text/html'
  end
  
  end
