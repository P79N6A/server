# coding: utf-8
class WebResource
  module HTTP
    Methods = %w{HEAD GET OPTIONS POST PUT}
    include URIs
    Host = {}

    def self.call env; puts "\e[35;1m" + (env['HTTP_HOST']||'') + "\e[2m" + env['REQUEST_PATH'] + "\e[0m <- \e[36;1m" + (env['HTTP_REFERER']||'') + "\e[0m   \e[30;1m" + (env['HTTP_USER_AGENT']||'') + "\e[0m"
      return [405,{},[]] unless Methods.member? env['REQUEST_METHOD']
      rawpath = env['REQUEST_PATH'].utf8.gsub /[\/]+/, '/'
      path = Pathname.new(rawpath).expand_path.to_s
      path += '/' if path[-1] != '/' && rawpath[-1] == '/'
      env['q'] = parseQs env['QUERY_STRING']
      path.R.environment(env).send env['REQUEST_METHOD']
    rescue Exception => x
      [500,{'Content-Type'=>'text/plain'},
       [[x.class,
         x.message,
         x.backtrace].join("\n")]]
    end

    def self.parseQs qs
      if qs
        h = {}
        qs.split(/&/).map{|e|
          k, v = e.split(/=/,2).map{|x|CGI.unescape x}
          h[(k||'').downcase] = v}
        h
      else
        {}
      end
    end

    def environment env = nil
      if env
        @r = env
        self
      else
        @r
      end
    end
    alias_method :env, :environment

    def HEAD; self.GET.do{|s,h,b|[s,h,[]]} end
    def OPTIONS; [200,{},[]] end
    def POST; [202,{},[]] end
    def PUT; [202,{},[]] end

    def GET
      @r[:Response] = {}
      @r[:links] = {}

      # bespoke handlers
      return fileResponse if node.file?
      return Host[@r['HTTP_HOST']][self] if Host[@r['HTTP_HOST']]
      return (chronoDir parts) if (parts[0] || '').match(/^(y(ear)?|m(onth)?|d(ay)?|h(our)?)$/i)

      # page pointers
      dp = [] # datetime parts
      dp.push parts.shift.to_i while parts[0] && parts[0].match(/^[0-9]+$/)
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

      sl = parts.empty? ? '' : (path[-1] == '/' ? '/' : '') # preserve trailing slash
      @r[:links][:prev] = p + '/' + parts.join('/') + sl + qs + '#prev' if p && R[p].e
      @r[:links][:next] = n + '/' + parts.join('/') + sl + qs + '#next' if n && R[n].e
      @r[:links][:up] = dirname + (dirname == '/' ? '' : '/') + qs + '#r' + path.sha2 unless path=='/'

      # resource set
      set = selectNodes
      return notfound if !set || set.empty?

      # response metadata
      format = selectMIME
      @r[:Response].update({'Link' => @r[:links].map{|type,uri|"<#{uri}>; rel=#{type}"}.intersperse(', ').join}) unless @r[:links].empty?
      @r[:Response].update({'Content-Type' => %w{text/html text/turtle}.member?(format) ? (format+'; charset=utf-8') : format,
                            'ETag' => [[R[HTML::SourceCode], # cache-bust on renderer,
                                        R['.conf/site.css'], # CSS, or doc changes
                                        *set].sort.map{|r|[r,r.m]}, format].join.sha2})
      # conditional body
      entity @r, ->{
        if set.size == 1 && set[0].mime == format
          set[0] # static file good to go
        else # transcode and/or merge sources
          if format == 'text/html'
            ::Kernel.load HTML::SourceCode if ENV['DEV']
            htmlDocument load set
          elsif format == 'application/atom+xml'
            renderFeed load set
          else # RDF formats
            g = RDF::Graph.new
            set.map{|n| g.load n.toRDF.localPath, :base_uri => n.stripDoc }
            g.dump (RDF::Writer.for :content_type => format).to_sym, :base_uri => self, :standard_prefixes => true
          end
        end}
    end

    def notfound; [404,{'Content-Type' => 'text/html'},[htmlDocument]] end

    # querystring -> Hash
    def q fromEnv = true
      fromEnv ? @r['q'] : HTTP.parseQs(query)
    end

    def inDoc; path == @r['REQUEST_PATH'] end

    # env -> ?querystring
    def qs; @r['QUERY_STRING'] && !@r['QUERY_STRING'].empty? && ('?'+@r['QUERY_STRING']) || '' end

    # Hash -> ?querystring
    def HTTP.qs h; '?'+h.map{|k,v|k.to_s + '=' + (v ? (CGI.escape [*v][0].to_s) : '')}.intersperse("&").join('') end

  end
  include HTTP
  module HTTP

    # parse list of hosts. hosts-file format but ignore IP address here
    def hosts
      lines.map{|l|
        l.split(' ')[1]}
    end

    #host bindings

    #redirect to open-source alternative
    Host['play.google.com'] = -> re {[302,{'Location' => "https://f-droid.org/en/packages/#{re.q['id']}/"},[]]}

    # actual URL is on file with third-party
    '.conf/hosts/minized'.R.hosts.map{|host| Host[host] = Short}

    # URI is encoded in another URI
    Host['exit.sc'] = Unwrap[:url]
    Host['l.instagram.com'] = Unwrap[:u]
    Host['lookup.t-mobile.com'] = Unwrap[:origURL]
    Host['images.duckduckgo.com'] = Host['proxy.duckduckgo.com'] = Unwrap[:u]

    # host CSS and fonts locally
    '.conf/hosts/font'.R.hosts.map{|host| Host[host] = Font}
  end
end
