# coding: utf-8
class WebResource
  module HTTP
    Methods = %w{HEAD GET OPTIONS}
    include URIs

    def self.call env
      method = env['REQUEST_METHOD']
      return [202,{},[]] unless Methods.member? method

      # bind hostname
      query = parseQs env['QUERY_STRING']
      host = query['host'] || query['site'] || env['HTTP_HOST'] || 'localhost'

      # clean path name
      rawpath = env['REQUEST_PATH'].utf8.gsub /[\/]+/, '/'

      # evaluate path expression
      path = Pathname.new(rawpath).expand_path.to_s
      path += '/' if path[-1] != '/' && rawpath[-1] == '/'

      # instantiate resource
      resource = R['//' + host + path].environment env

      # call request method
      resource.send(method).do{|status,head,body|
        # log response
        color = if resource.track?
                  '31' # red
                elsif status==200
                  '32' # green
                elsif status==304
                  '37' # white
                else
                  '30' # gray
                end
        referer = env['HTTP_REFERER']
        referrer = if referer
                     r = referer.R
                     "\e[37;7m" + (r.host || '') + "\e[0m" + (r.path || '') + "\e[0m -> "
                   else
                     ''
                   end
        puts "\e[7m" + (method == 'GET' ? ' ' : '') + method + "\e[" + color + ";1m "  + status.to_s + "\e[0m " + referrer + "\e[" + color + ";1;7mhttps://" + host + "\e[0m\e["+color+";1m" + path + "\e[0m"
        [status,head,body]}
    rescue Exception => x
      [500,{'Content-Type'=>'text/plain'},
       method=='HEAD' ? [] : [[x.class,x.message,x.backtrace].join("\n")]]
    end

    def environment env = nil
      if env
        @r = env
        self
      else
        @r || {}
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
      @r[:Response] = {} # headers
      @r[:links] = {}
      return Host[host][self]      if Host[host]     # host lambda
      return Path[path][self]      if Path[path]     # path lambda
      return fileResponse          if node.file?     # static-file
      return shortURL              if shortURL?      # remote URL-expansion
      return track                 if track?         # activity tracker
      return (chronoDir parts)     if chronoDir?     # time-slice container
      refs = localNodes                              # local resource(s)
      return (files refs) if refs && !refs.empty?
      return notfound if localhost?                  # no local resource
      fetch                                          # remote resource(s)
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
      dateMeta # page hints, something adjacent may exist
      [404,{'Content-Type' => 'text/html'},[htmlDocument]]
    end

    def deny
      R['.conf/squid/ERR_ACCESS_DENIED'].env(env).setMIME('text/html').fileResponse
    end

    # environment -> Hash
    def q
      @q ||= HTTP.parseQs qs[1..-1]
    end

    # environment -> String
    def qs
      if @r && @r['QUERY_STRING'] && !@r['QUERY_STRING'].empty?
        '?' + @r['QUERY_STRING']
      else
        ''
      end
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

  end
  include HTTP
end
