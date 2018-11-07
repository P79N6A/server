# coding: utf-8
class WebResource
  module HTTP
    Methods = %w{HEAD GET OPTIONS}
    include URIs

    def self.call env
      method = env['REQUEST_METHOD']
      return [202,{},[]] unless Methods.member? method
      # parse query
      env['query'] = query = parseQs env['QUERY_STRING']
      # bind hostname via query or header
      host = query['host'] || query['site'] || env['HTTP_HOST'] || 'localhost'
      # bind pathname
      rawpath = env['REQUEST_PATH'].utf8.gsub /[\/]+/, '/'
      # evaluate path-expression, preserving trailing-slash
      path = Pathname.new(rawpath).expand_path.to_s
      path += '/' if path[-1] != '/' && rawpath[-1] == '/'
      # referrer
      referer = env['HTTP_REFERER']
      referrer = if referer
                   r = referer.R
                   " \e[36;1m" + (r.host || '') + "\e[2m" + (r.path || '') + "\e[0m -> "
                 else
                   ' '
                 end
      # logging
      puts "\e[7m" + (method == 'GET' ? ' ' : '') + method + "\e[0m" + referrer + "\e[32;1m" + host + "\e[7m" + path + "\e[0m"
      # dispatch request
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
                 [ s, h, []]} end
    def OPTIONS; [200,{},[]]  end
    def POST;    [202,{},[]]  end
    def PUT;     [202,{},[]]  end

    def GET
      # init response headers
      @r[:Response] = {}
      @r[:links] = {}
      # response handler, first match finishes
      return fileResponse if node.file?               # static file
      return Host[host][self] if Host[host]           # host match
      return Host[subdomain][self] if Host[subdomain] # subdomain-wildcard match
      return (chronoDir parts) if (parts[0]||'').match(/^(y(ear)?|m(onth)?|d(ay)?|h(our)?)$/i) # dynamic redirect to current time-segment
      filesResponse                                   # static files
    end

    def entity env, lambda = nil
      etags = env['HTTP_IF_NONE_MATCH'].do{|m| m.strip.split /\s*,\s*/ }
      if etags && (etags.include? env[:Response]['ETag'])
        # client has entity
        [304, {}, []]
      else # produce entity
        # call entity-producer lambda
        body = lambda ? lambda.call : self
        # dispatch file-references to Rack file-handler
        if body.class == WebResource
          (Rack::File.new nil).serving((Rack::Request.new env),body.localPath).do{|s,h,b|
            [s,h.update(env[:Response]),b]} # attach headers to response and return
        else # return static entity
          [(env[:Status]||200), env[:Response], [body]]
        end
      end
    end

    def notfound; [404,{'Content-Type' => 'text/html'},[htmlDocument]] end

    # query String
    def qs
      @r['QUERY_STRING'] && !@r['QUERY_STRING'].empty? && ('?'+@r['QUERY_STRING']) || ''
    end

    # query Hash
    def q
      # use memoized parse if available
      @r && @r['query'] || (HTTP.parseQs query)
    end

    # query String -> query Hash
    def HTTP.parseQs qs
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

    # query Hash -> query String
    def HTTP.qs h
      '?' + h.map{|k,v|
        k.to_s + '=' + (v ? (CGI.escape [*v][0].to_s) : '')
      }.intersperse("&").join('')
    end

    CDN = -> re {
      case re.ext
      when 'css'
        CSS
      when /^(jpg|png|webp)$/i
        CachedImage[re]
      else
        [404,{},[]]
      end}

  end
  include HTTP
end
