class WebResource
  module HTTP

    def fetch
      # URL
      format = host.match?(/reddit.com$/) ? '.rss' : ''
      urlHTTPS = 'https://' + host + path + format +  qs
      urlHTTP  = 'http://'  + host + path + qs

      # storage
      hash = (path + qs).sha2
      updates = []
      cache = R['/cache/Resource/' + host + path + (path[-1] == '/' ? '' : '/') + (qs && !qs.empty? && (qs.sha2 + '/') || '')]
      etag  = cache + 'etag'  # etag URI
      mime  = cache + 'MIME'  # MIME URI   TODO use file-extension on body-file
      mtime = cache + 'mtime' # mtime URI  TODO use fs mtime
      body = cache + 'body'   # body URI

      # metadata
      head = {} # header storage
      head['User-Agent'] = env['HTTP_USER_AGENT']
      _eTag  = nil    # cached-entity "tag" (version identifier)
      _mimeType = nil # cached-entity MIME
      _modified = nil # cached-entity mtime
      _mimeType = mimeType = mime.readFile if mime.e
      if etag.e # prefer ETag if one exists
        _eTag = etag.readFile
        head["If-None-Match"] = _eTag unless _eTag.empty?
      elsif mtime.e
        _modified = mtime.readFile.to_time
        head["If-Modified-Since"] = _modified.httpdate
      end

      # fetcher lambda
      fetch = -> url {
        begin
          puts "FETCH #{url}" unless @r

          open(url, head) do |response|
            eTag = response.meta['etag']
            mimeType = response.meta['content-type']
            modified = response.last_modified || Time.now rescue Time.now
            etag.writeFile eTag if eTag && !eTag.empty? && eTag != _eTag # update ETag
            mime.writeFile mimeType if mimeType != _mimeType             # update MIME
            mtime.writeFile modified.iso8601 if modified != _modified    # update timestamp
            resp = response.read
            unless body.e && body.readFile == resp
              # updated content
              body.writeFile resp
              updates.concat case mimeType
                             when /^application\/atom/
                               body.indexFeed
                             when /^application\/rss/
                               body.indexFeed
                             when /^application\/xml/
                               body.indexFeed
                             when /^text\/html/
                               if FeedURI[uri] # add URL to <feeds.u> to override defective MIME headers
                                 body.indexFeed
                               else
                                 body.indexHTML
                               end
                             when /^text\/xml/
                               body.indexFeed
                             else
                               []
                             end
             end
          end
        # 304 isn't an error
        rescue OpenURI::HTTPError => e
          case e.message
          when /304/
#            puts "GET 304 #{uri}" unless @r
          else
            raise
          end
        end}

      # update cache
      fresh = false
      staticResource = _mimeType && (_mimeType.match?(MediaMIME) ||
                                     _mimeType.match?(/javascript/) ||
                                     %w{application/octet-stream text/css}.member?(_mimeType))
      unless fresh || staticResource
        begin
          fetch[urlHTTPS]
        rescue
          fetch[urlHTTP]
        end
      end

      # response
      if @r # HTTP context
        if !updates.empty?
          files updates
        elsif body.exist?
          @r[:Response]['Content-Type'] = mimeType
          body.env(env).fileResponse
        else
          notfound
        end
      else
        self
      end
    rescue
      @r ? notfound : self
    end

    def multiFetch resources=nil
      (resources || open(localPath).readlines.map(&:chomp).map(&:R)).map &:fetch
    end

    alias_method :cache, :fetch
  end
end
