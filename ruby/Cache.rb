class WebResource
  module HTTP

    # resource cached once. no origin-check overhead, for URIs specific to a version
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

    # cached resource with remote origin
    def cacheDynamic
      # cache URI
      hash = (path + qs).sha2
      cache = R['/cache/Resource/' + host + '/' + hash[0..2] + '/' + hash[3..-1] + '/']
      # storage URIs
      head = {}               # HTTP header
      etag  = cache + 'etag'  # cached etag URI
      mime  = cache + 'MIME'  # cached MIME URI
      mtime = cache + 'mtime' # cached mtime URI
      body = cache + 'body'   # cached body URI

      # metadata from previous response
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
        url = 'http' + (q.has_key?('80') ? '' : 's') + ':' + url if url[0..1] == '//' # prepend scheme
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

  end
end
