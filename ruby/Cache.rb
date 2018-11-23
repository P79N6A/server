class WebResource
  module HTTP
    JSpath = %w{wp-content}
    # static-resource cache:
    # note: no origin roundtrip on cache hits, but updates require a URI change. recommended for hashed-content derived identifiers
    def cacheStatic
      # storage URI
      hash = (path + qs).sha2
      container = R['/cache/StaticResource/' + host + '/' + hash[0..2] + '/' + hash[3..-1] + '/']
      type = ext
      type = 'jpg' if !type || type.empty?
      file = container + 'i.' + type

      # fetch
      # note: duplicate GETs during an origin fetch will 404 when container exists but file doesn't. given the vastness of the web the chance of two users stumbling across the same file at the same time seems exceedingly "rare", at least when the proxy is on localhost and only has one user. so the container is the lockfile that prevents multiple concurrent origin fetches 
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

    # cache resource of remote origin
    def cacheDynamic
      # storage URIs
      hash = (path + qs).sha2
      cache = R['/cache/Resource/' + host + path + (path[-1] == '/' ? '' : '/') + (qs && !qs.empty? && (qs.sha2 + '/') || '')]
      etag  = cache + 'etag'  # cached etag URI
      mime  = cache + 'MIME'  # cached MIME URI
      mtime = cache + 'mtime' # cached mtime URI
      body = cache + 'body'   # cached body URI

      # metadata from previous response
      head = {} # HTTP header storage
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

      # update
      begin
        url = uri # locator
        # prefer HTTPS with explicit HTTP via ?80 query
        url = 'http' + (q.has_key?('80') ? '' : 's') + ':' + url if url[0..1] == '//' # prepend scheme
        open(url, head) do |response|
          puts " GET #{url}"
          curEtag = response.meta['etag']
          curMIME = response.meta['content-type']
          curMtime = response.last_modified || Time.now rescue Time.now
          etag.writeFile curEtag if curEtag && !curEtag.empty? && curEtag != priorEtag # update ETag
          mime.writeFile curMIME if curMIME != priorMIME                               # update MIME
          mtime.writeFile curMtime.iso8601 if curMtime != priorMtime                   # update timestamp
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

  end
end
