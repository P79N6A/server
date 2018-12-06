class WebResource
  module HTTP

    def fetch
      # URL
      format = host.match?(/reddit.com$/) ? '.rss' : ''
      url     = 'https://' + host + path + format +  qs
      urlHTTP = 'http://'  + host + path + qs

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
              puts "#{mimeType} :: #{url}"
              updates.concat case mimeType
                             when /^application\/atom/
                               body.indexFeed
                             when /^application\/rss/
                               body.indexFeed
                             when /^application\/xml/
                               body.indexFeed
                             when /^text\/html/
                               if FeedURI[uri] # add to <config/feeds.u> to override defective MIME header 
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
        rescue OpenURI::HTTPError => e
          case e.message
          when /304/
            puts " 304 #{url}"
          else
            puts [url, e.class, e.message].join ' '
            raise
          end
        end}

      # update cache
      if _mimeType && (_mimeType.match?(MediaMIME) || _mimeType.match?(/javascript/) ||  %w{application/octet-stream text/css}.member?(_mimeType))
        #puts "HIT #{uri}"
      else
        begin # HTTPS
          fetch[url]
        rescue # HTTP
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

    def track
      case host
      when /google.com$/
        google
      else
        case ext
        when 'css'
          [200, {'Content-Type' => 'text/css', 'Content-Length' => 0}, []]
        when 'gif'
          favicon
#        when 'jpg'
#          cache
        when 'js'
          [200, {'Content-Type' => 'application/javascript'}, []]
        when 'png'
          cache
        else
          deny
        end
      end
    end

    def google
      case parts[0]
      when 'complete'
        puts q['q']
        [200, {'Content-Length' => 0}, []]
      when 'maps'
        (if ll = path.match(/@(-?\d+\.\d+),(-?\d+\.\d+)/)
         lat = ll[1] ; lon = ll[2]
         "https://tools.wmflabs.org/geohack/geohack.php?params=#{lat};#{lon}"
        elsif q.has_key? 'q'
          "https://www.openstreetmap.org/search?query=#{URI.escape q['q']}"
        else
          'https://www.openstreetmap.org/'
         end).do{|loc|
          [302,{'Location' => loc},[]]}
      when 'search'
        [302, {'Location' =>  "https://duckduckgo.com/?q=#{URI.escape (q['q']||'')}"},[]]
      else
        deny
      end
    end

    # remove duckduckgo proxy
    Path['/iu/'] = -> re {[302,{'Location' => re.q['u']},[]]}

  end
end
