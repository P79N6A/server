# coding: utf-8
class WebResource
  module HTTP
    Methods = %w{HEAD GET OPTIONS POST PUT}
    include URIs

    def self.call env
      method = env['REQUEST_METHOD']
      return [405,{},[]] unless Methods.member? method
      host = env['HTTP_HOST'] || 'localhost'
      rawpath = env['REQUEST_PATH'].utf8.gsub /[\/]+/, '/'
      path = Pathname.new(rawpath).expand_path.to_s
      path += '/' if path[-1] != '/' && rawpath[-1] == '/'
      referer = env['HTTP_REFERER']
      referrer = if referer
                   r = referer.R
                   " \e[36;1m" + (r.host || '') + "\e[2m" + (r.path || '') + "\e[0m ❱ "
                 else
                   ' '
                 end
      puts "\e[7m" + (method == 'GET' ? ' ' : '') + method + "\e[0m" + referrer + "\e[32;1m" + host + "\e[0m" + path
      env['q'] = parseQs env['QUERY_STRING']
      R['//' + host + path].environment(env).send method
    rescue Exception => x
      [500,{'Content-Type'=>'text/plain'},
       method=='HEAD' ? [] : [[x.class,x.message,x.backtrace].join("\n")]]
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

    def HEAD
     self.GET.do{| s, h, b|
                 [ s, h, []] } end
    def OPTIONS; [200,{},[]]   end
    def POST;    [202,{},[]]   end
    def PUT;     [202,{},[]]   end

    def GET
      @r[:Response] = {}
      @r[:links] = {}
      return fileResponse if node.file?                                                        # static file
      return (chronoDir parts) if (parts[0]||'').match(/^(y(ear)?|m(onth)?|d(ay)?|h(our)?)$/i) # to current time-dir
      return Host[host][self] if Host[host]                                                    # hostname mapping
      hosts = host.split('.')[1..-1].unshift('*').join '.'                                     # wildcard-subdomain mapping
      return Host[hosts][self] if Host[hosts]
      filesResponse                                                                            # file-mapped resources
    end

    def fileResponse
      @r[:Response].update({'Content-Type' => %w{text/html text/turtle}.member?(mime) ? (mime+'; charset=utf-8') : mime,
                            'ETag' => [m,size].join.sha2,
                            'Access-Control-Allow-Origin' => '*'
                           })
      @r[:Response].update({'Cache-Control' => 'no-transform'}) if mime.match /^(audio|image|video)/
      if q.has_key?('preview') && ext.match(/(mp4|mkv|png|jpg)/i)
        filePreview
      else
        entity @r
      end
    end

    def filesResponse set=nil
      if !set || set.empty?
        set = selectNodes
        paginate
      end
      return notfound if !set || set.empty?
      format = selectMIME
      @r[:Response].update({'Link' => @r[:links].map{|type,uri|"<#{uri}>; rel=#{type}"}.intersperse(', ').join}) unless @r[:links].empty?
      @r[:Response].update({'Content-Type' => %w{text/html text/turtle}.member?(format) ? (format+'; charset=utf-8') : format,
                            'ETag' => [[R[HTML::SourceCode], # cache-bust on renderer,
                                        R['.conf/site.css'], # CSS, or doc changes
                                        *set].sort.map{|r|[r,r.m]}, format].join.sha2})
      entity @r, ->{
        if set.size == 1 && set[0].mime == format
          set[0] # no transcode, file as response body
        else # merge and transcode
          if format == 'text/html'
            ::Kernel.load HTML::SourceCode if ENV['DEV']
            htmlDocument load set
          elsif format == 'application/atom+xml'
            renderFeed load set
          else # RDF
            g = RDF::Graph.new
            set.map{|n| g.load n.toRDF.localPath, :base_uri => n.stripDoc }
            g.dump (RDF::Writer.for :content_type => format).to_sym, :base_uri => self, :standard_prefixes => true
          end
        end}
    end

    def entity env, body = nil
      etags = env['HTTP_IF_NONE_MATCH'].do{|m| m.strip.split /\s*,\s*/ }
      if etags && (etags.include? env[:Response]['ETag'])
        # client has entity, tell it
        [304, {}, []]
      else # produce entity
        # entity-producing lambda or file-reference
        body = body ? body.call : self
        # dispatch to Rack for file-reference handling
        if body.class == WebResource
          (Rack::File.new nil).serving((Rack::Request.new env),body.localPath).do{|s,h,b|
            [s,h.update(env[:Response]),b]}
        else
          [(env[:Status]||200), env[:Response], [body]]
        end
      end
    end

    def notfound; [404,{'Content-Type' => 'text/html'},[htmlDocument]] end

    def paginate
      dp = [] # date parts
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
      # preserve trailing slash
      sl = parts.empty? ? '' : (path[-1] == '/' ? '/' : '')
      # add page pointers to HTTP header
      @r[:links][:prev] = p + '/' + parts.join('/') + sl + qs + '#prev' if p && R[p].e
      @r[:links][:next] = n + '/' + parts.join('/') + sl + qs + '#next' if n && R[n].e
      @r[:links][:up] = dirname + (dirname == '/' ? '' : '/') + qs + '#r' + path.sha2 unless path=='/'
    end

    # environment -> ?querystring
    def qs; @r['QUERY_STRING'] && !@r['QUERY_STRING'].empty? && ('?'+@r['QUERY_STRING']) || '' end
    # environment | URI -> ?querystring -> Hash
    def q fromEnv = true
      fromEnv ? @r['q'] : HTTP.parseQs(query)
    end
    # ?querystring -> Hash
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
    # Hash -> ?querystring
    def HTTP.qs h; '?'+h.map{|k,v|k.to_s + '=' + (v ? (CGI.escape [*v][0].to_s) : '')}.intersperse("&").join('') end

  end
  include HTTP
end
