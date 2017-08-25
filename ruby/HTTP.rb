# coding: utf-8
class R

  def R.call e
    return [405,{},[]] unless %w{HEAD GET}.member? e['REQUEST_METHOD']
    return [404,{},[]] if e['REQUEST_PATH'].match(/\.php$/i)
    e['HTTP_X_FORWARDED_HOST'].do{|h|e['SERVER_NAME']=h}    # hostname
    e['SERVER_NAME'] = e['SERVER_NAME'].gsub /[\.\/]+/, '.' # strip path chars
    rawpath = e['REQUEST_PATH'].utf8.gsub /[\/]+/, '/'      # collapse sequence of /
    path = Pathname.new(rawpath).expand_path.to_s           # evaluate path
    path += '/' if path[-1] != '/' && rawpath[-1] == '/'    # preserve trailing-slash
    resource = R["//"+e['SERVER_NAME']+path] # resource instance
    e['uri'] = resource.uri                  # resource URI
    e[:Response] = {}; e[:Links] = {} # init response headers
    (resource.setEnv e).send e['REQUEST_METHOD']
  rescue Exception => x
    msg = [x.class,x.message,x.backtrace].join "\n"
    puts msg
    [500,{'Content-Type' => 'text/html'},
     ["<html><head><style>","
body {background-color:#222; font-size:1.2em; text-align:center}
pre {text-align:left; display:inline-block; background-color:#000; color:#fff; font-weight:bold; border-radius:.6em; padding:1em}
.number {color:#0f0; font-weight:normal; font-size:1.1em}",
      '</style></head><body><pre>',
      msg.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;').gsub(/([0-9\.]+)/,'<span class=number>\1</span>'),
      '</pre></body></html>']]
  end

  def HEAD; self.GET.do{|s,h,b|[s,h,[]]} end

  def GET
    return notfound if path.match /^\/(cache|domain)/
    return justPath.fileGET if justPath.file?
    return [303,@r[:Response].update({'Location'=> Time.now.strftime('/%Y/%m/%d/%H?')+@r['QUERY_STRING']}),[]] if path=='/'
    set = nodeset
    return notfound if !set || set.empty?
    @r[:Response].update({'Link' => @r[:Links].map{|type,uri|"<#{uri}>; rel=#{type}"}.intersperse(', ').join}) unless @r[:Links].empty?
    @r[:Response].update({'Content-Type' => format, 'ETag' => [set.sort.map{|r|[r,r.m]}, format].join.sha2})
    condResponse ->{ # body called on-demand
      if set.size==1 && set[0].mime==format
        set[0] # static body
      else # dynamic body
        if format == 'text/html' # HTML
          HTML[R.load(set),self] # render <- load
        else # RDF
          load(set).dump (RDF::Writer.for :content_type => format).to_sym, :base_uri => self, :standard_prefixes => true
        end
      end}
  end

  def fileGET
    @r[:Response].update({'Content-Type' => mime, 'ETag' => [m,size].join.sha2})
    @r[:Response].update({'Cache-Control' => 'no-transform'}) if mime.match /^(audio|image|video)/
    if q.has_key?('thumb') && ext.match(/(mp4|mkv|png|jpg)/i)
      thumb = thumbFile
      if !thumb.e
        if mime.match(/^video/)
          `ffmpegthumbnailer -s 256 -i #{sh} -o #{thumb.sh}`
        else
          `gm convert #{sh} -thumbnail "256x256" #{thumb.sh}`
        end
      end
      thumb.e && thumb.setEnv(env).condResponse || notfound
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

  def nodeset
    query = env['QUERY_STRING']
    qs = query && !query.empty? && ('?' + query) || ''
    parts = path[1..-1].split '/'

    # month/day/year/hour traversal pointers
    dp = [] # date parts
    dp.push parts.shift.to_i while parts[0] && parts[0].match(/^[0-9]+$/)
    n = nil; p = nil # init pointers
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
    # add pointers to request-meta
    s = (!parts.empty? || uri[-1]=='/') ? '/' : ''
    env[:Links][:prev] = p + s + parts.join('/') + qs if p && (R['//' + host + p].e || R[p].e)
    env[:Links][:next] = n + s + parts.join('/') + qs if n && (R['//' + host + n].e || R[n].e)
    env[:Links][:up] = dirname + '/' + qs # parent
    # nodes
    [self, justPath].uniq.map{|p|
      if p.node.directory?
        if q.has_key? 'find'
          expression = '-ipath ' + ('*' + q['find'] + '*').sh
          `find #{p.sh} #{expression} | head -n 1024`.lines.map{|l|R.unPOSIX l.chomp}
        elsif q.has_key? 'q'
          `grep -ril #{q['q'].gsub(' ','.*').sh} #{p.sh} | head -n 1024`.lines.map{|r|R.unPOSIX r.chomp}
        else
          if uri[-1] == '/'
            env[:Links][:up] = path[0..-2] + qs # pointer to summary URI (sans slash)
            (p+'index.*').glob || [p, p.children]
          else
            env[:Links][:down] = p.path + '/' + qs # pointer to full-content URI (trailing-slash)
            p
          end
        end
      else # arbitrary glob or basic pattern to find documents off base URI
        (p.match(/\*/) ? p : (p+'.*')).glob
      end
    }.flatten.compact.select &:exist?
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
