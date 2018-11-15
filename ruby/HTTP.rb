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
                   " \e[36;1m" + (r.host || '') + "\e[2m" + (r.path || '') + "\e[0m -> "
                 else
                   ' '
                 end
      puts "\e[7m" + (method == 'GET' ? ' ' : '') + method + "\e[0m" + referrer + "\e[32;1m" + host + " \e[7m" + path + "\e[0m"

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
      # response, first match wins
      return fileResponse          if node.file?       # local file
      return Host[host][self]      if Host[host]       # host lambda
      return Host[subdomain][self] if Host[subdomain]  # subdomain lambda
      return (chronoDir parts)     if chronoDir?       # time-dir
      ns = localNodes
      return (filesResponse ns)    if ns && !ns.empty? # local resource
      case ext
      when 'css'
        return CSS                                     # local CSS
      when ImgExt
        return cacheStatic                             # remote file
      else
        return cacheDynamic                            # remote resource
      end
    end

    def cacheStatic
      return notfound if localhost?

      # cache-item URI
      hash = (host + path + qs).sha2
      container = R['/.cache/' + hash[0..2] + '/' + hash[3..-1] + '/']
      type = ext
      type = 'jpg' if !type || type.empty?
      file = container + 'i.' + type

      # fetch
      if !container.exist?
        container.mkdir
        url = uri
        if url[0..1] == '//' # schemeless URI
          scheme = env['SERVER_PORT'] == 80 ? 'http' : 'https'
          url = scheme + ':' + url
        end
        puts " GET #{url}"
        open(url) do |response|
          file.writeFile response.read
        end
      end

      # deliver
      if file.exist?
        file.env(env).fileResponse
      else
        notfound
      end
    end

    def cacheDynamic
      notfound
    end

    # conditional responder
    def entity env, lambda = nil
      etags = env['HTTP_IF_NONE_MATCH'].do{|m| m.strip.split /\s*,\s*/ }
      if etags && (etags.include? env[:Response]['ETag'])
        [304, {}, []] # client has entity, return
      else # produce entity
        body = lambda ? lambda.call : self
        if body.class == WebResource
          # hand reference to file-handler
          (Rack::File.new nil).serving((Rack::Request.new env),body.localPath).do{|s,h,b|
            [s,h.update(env[:Response]),b]} # attach headers and return
        else
          [(env[:Status]||200), env[:Response], [body]]
        end
      end
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

    def filesResponse set
      return notfound if !set || set.empty?
      # header
      dateMeta
      format = selectMIME
      @r[:Response].update({'Link' => @r[:links].map{|type,uri|"<#{uri}>; rel=#{type}"}.intersperse(', ').join}) unless @r[:links].empty?
      @r[:Response].update({'Content-Type' => %w{text/html text/turtle}.member?(format) ? (format+'; charset=utf-8') : format,
                            'ETag' => [[R[HTML::SourceCode], # cache-bust on renderer,
                                        R['.conf/site.css'], # CSS, or doc changes
                                        *set].sort.map{|r|[r,r.m]}, format].join.sha2})
      # body
      entity @r, ->{
        if set.size == 1 && set[0].mime == format
          set[0] # no transcode - on-file response body
        else # merge and/or transcode
          if format == 'text/html'
            ::Kernel.load HTML::SourceCode if ENV['DEV']
            htmlDocument load set
          elsif format == 'application/atom+xml'
            renderFeed load set
          else # RDF
            g = RDF::Graph.new
            set.map{|n|
              g.load n.toRDF.localPath, :base_uri => n.stripDoc }
            g.dump (RDF::Writer.for :content_type => format).to_sym, :base_uri => self, :standard_prefixes => true
          end
        end}
    end

    def notfound
      dateMeta
      [404,{'Content-Type' => 'text/html'},[htmlDocument]]
    end

    # query String
    def qs
      @r['QUERY_STRING'] && !@r['QUERY_STRING'].empty? && ('?'+@r['QUERY_STRING']) || ''
    end

    # query Hash
    def q
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

  end
  include HTTP
end
