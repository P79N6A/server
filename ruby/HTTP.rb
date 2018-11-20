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
      return fileResponse          if node.file?       # local static-file
      return Host[host][self]      if Host[host]       # host lambda
      return Host[subdomain][self] if Host[subdomain]  # subdomain lambda
      return (chronoDir parts)     if chronoDir?       # time-dir
      ns = localNodes
      return (filesResponse ns)    if ns && !ns.empty? # local resource
      return notfound if localhost?                    # no local resource found
      case ext
      when 'css'
        return CSS                                     # local CSS
      when 'js'
        return notfound                                # local JS
      when ImgExt
        return cacheStatic                             # remote static-file
      else
        return cacheDynamic                            # remote resource
      end
    end

    # static resource. no origin-check overhead, but only use for URIs specific to a version
    def cacheStatic
      # cache-URI
      hash = (path + qs).sha2
      container = R['/cache/StaticResource/' + host + '/' + hash[0..2] + '/' + hash[3..-1] + '/']
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

    # resource from remote origin
    def cacheDynamic
      # cache URI
      hash = (path + qs).sha2
      cache = R['/cache/Resource/' + host + '/' + hash[0..2] + '/' + hash[3..-1] + '/']

      # metadata storage
      head = {}               # HTTP header
      etag  = cache + 'etag'  # cached etag URI
      mime  = cache + 'MIME'  # cached MIME URI
      mtime = cache + 'mtime' # cached mtime URI
      body = cache + 'body'   # cached body URI

      # load metadata from previous response
      priorEtag  = nil # cached etag value
      priorMIME  = nil # cached MIME value
      priorMtime = nil # cached mtime value
      if etag.e
        priorEtag = etag.readFile
        head["If-None-Match"] = priorEtag unless priorEtag.empty?
      elsif mtime.e
        priorMtime = mtime.readFile.to_time
        head["If-Modified-Since"] = priorMtime.httpdate
      end
      priorMIME = curMIME = mime.readFile if mime.e

      # cache update
      begin
        url = uri # locator
        url = 'https:' + url if url[0..1] == '//' # prepend scheme
        open(url, head) do |response|
          puts " GET #{url}"
          curEtag = response.meta['etag']
          curMIME = response.meta['content-type']
          curMtime = response.last_modified || Time.now rescue Time.now
          etag.writeFile curEtag if curEtag && !curEtag.empty? && curEtag != priorEtag # update ETag
          mime.writeFile curMIME if curMIME != priorMIME # update MIME
          mtime.writeFile curMtime.iso8601 if curMtime != priorMtime # update timestamp
          resp = response.read
          unless body.e && body.readFile == resp
            body.writeFile resp
          end
        end
      rescue OpenURI::HTTPError => error
        msg = error.message
        puts [url,msg].join("\t") unless msg.match(/304/)
      end

      # deliver
      if body.exist?
        @r[:Response]['Content-Type'] = curMIME
        body.env(env).fileResponse
      else
        notfound
      end
    rescue Exception => e
      puts uri, e.class, e.message
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
      @r[:Response]['Content-Type'] ||= (%w{text/html text/turtle}.member?(mime) ? (mime + '; charset=utf-8') : mime)
      @r[:Response].update({'ETag' => [m,size].join.sha2, 'Access-Control-Allow-Origin' => '*'})
      @r[:Response].update({'Cache-Control' => 'no-transform'}) if @r[:Response]['Content-Type'].match /^(audio|image|video)/
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
      @r[:Response].update({'Content-Type' => %w{text/html text/turtle}.member?(format) ? (format+'; charset=utf-8') : format, 'ETag' => [set.sort.map{|r|[r,r.m]}, format].join.sha2})
      # body
      entity @r, ->{
        if set.size == 1 && set[0].mime == format
          set[0] # on-file response body
        else
          if format == 'text/html'
            ::Kernel.load HTML::SourceCode if ENV['DEV']
            htmlDocument load set
          elsif format == 'application/atom+xml'
            renderFeed load set
          else # RDF format
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
