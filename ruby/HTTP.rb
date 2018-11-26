# coding: utf-8
class WebResource
  module HTTP
    Methods = %w{HEAD GET OPTIONS}
    include URIs

    def self.call env
      method = env['REQUEST_METHOD']
      return [202,{},[]] unless Methods.member? method
      # parsed query
      env['query'] = query = parseQs env['QUERY_STRING']
      # hostname
      host = query['host'] || query['site'] || env['HTTP_HOST'] || 'localhost'
      # raw pathname
      rawpath = env['REQUEST_PATH'].utf8.gsub /[\/]+/, '/'
      # evaluated path-expression
      path = Pathname.new(rawpath).expand_path.to_s
      path += '/' if path[-1] != '/' && rawpath[-1] == '/'

      # logging
      referer = env['HTTP_REFERER']
      referrer = if referer
                   r = referer.R
                   (r.host || '') + "\e[2m" + (r.path || '') + "\e[0m -> "
                 else
                   ''
                 end
      puts "\e[7m" + (method == 'GET' ? ' ' : '') + method + "\e[0m " + referrer + "\e[36;1m" + host + " \e[7m" + path + "\e[0m"

      # call request method
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
      # response headers
      @r[:Response] = {}
      @r[:links] = {}

      # local resources
      return favicon               if path == '/favicon.ico' # host icon
      return fileResponse          if node.file?      # local static-file
      return Host[host][self]      if Host[host]      # host lambda
      return Host[subdomain][self] if Host[subdomain] # subdomain lambda
      return (chronoDir parts)     if chronoDir?      # time-slice container
      refs = localNodes
      return (files refs) if refs && !refs.empty?     # local resource(s)
      return notfound if localhost?                   # no local resource found

      # remote resources
      case ext
      when /^(jpg|jpg:large|png|webp)$/i
        return cacheStatic                             # remote static-file
      when 'js'
        if (JShost.member? host) || (JSpath.member? parts[0])
          return cacheDynamic                          # allowed remote script
        else
          return notfound                              # denied remote script
        end
      end
      cacheDynamic                                     # remote resource(s)
    end

    # conditional responder
    def entity env, lambda = nil
      etags = env['HTTP_IF_NONE_MATCH'].do{|m| m.strip.split /\s*,\s*/ }
      if etags && (etags.include? env[:Response]['ETag'])
        [304, {}, []] # client has entity, exit
      else # produce entity
        body = lambda ? lambda.call : self
        if body.class == WebResource
          # hand reference to file handler
          (Rack::File.new nil).serving((Rack::Request.new env),body.localPath).do{|s,h,b|
            [s,h.update(env[:Response]),b]} # attach metadata and return
        else
          [(env[:Status]||200), env[:Response], [body]]
        end
      end
    end

    def notfound
      dateMeta
      [404,{'Content-Type' => 'text/html'},[htmlDocument]]
    end

    # String -> Hash
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

    # Hash -> String
    def HTTP.qs h
      '?' + h.map{|k,v|
        k.to_s + '=' + (v ? (CGI.escape [*v][0].to_s) : '')
      }.intersperse("&").join('')
    end

    # env -> String
    def qs
      @r['QUERY_STRING'] && !@r['QUERY_STRING'].empty? && ('?'+@r['QUERY_STRING']) || ''
    end

    # (env || URI) -> Hash
    def q
      @r && @r['query'] || (HTTP.parseQs query)
    end

  end
  include HTTP
end
