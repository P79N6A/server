class WebResource
  module HTTP

    def cache
      # remote-resource reference
      url = uri + qs # locator
      url = 'https:' + url if url[0..1] == '//' # free scheme?
      # remote-resource handle
      source = url.R.env env

      # storage
      hash = (path + qs).sha2
      cache = R['/cache/Resource/' + host + path + (path[-1] == '/' ? '' : '/') + (qs && !qs.empty? && (qs.sha2 + '/') || '')]
      etag  = cache + 'etag'  # cached etag URI
      mime  = cache + 'MIME'  # cached MIME URI
      mtime = cache + 'mtime' # cached mtime URI
      body = cache + 'body'   # cached body URI

      # load metadata
      head = {} # header storage
      priorEtag  = nil # cached etag
      priorMIME  = nil # cached MIME
      priorMtime = nil # cached mtime
      if mime.e
        priorMIME = curMIME = mime.readFile
      end
      if etag.e
        priorEtag = etag.readFile
        head["If-None-Match"] = priorEtag unless priorEtag.empty?
      elsif mtime.e
        priorMtime = mtime.readFile.to_time
        head["If-Modified-Since"] = priorMtime.httpdate
      end

      fetch = -> url {
        puts " GET #{url}"
        begin
          open(url, head) do |response|
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
          case error.message
          when /304/
            puts " 304 #{url}"
          else
            puts error.message
          end
        end}

      # conditional update
      if priorMIME && (priorMIME.match?(MediaMIME) ||
                       %w{application/octet-stream text/css}.member?(priorMIME))
       # mediafile HIT
      else
        begin # HTTPS
          fetch[source.uri]
        rescue
          if source.scheme != 'http'
            # HTTP fallback
            fetch['http://' + source.host + source.path + source.qs]
          end
        end
      end

      # deliver
      if body.exist?
        @r[:Response]['Content-Type'] = curMIME
        body.env(env).fileResponse
      else
        notfound
      end
    end
  end
end
