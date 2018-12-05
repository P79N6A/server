class WebResource
  module HTTP

    def fetch
      format = host.match?(/reddit.com$/) ? '.rss' : ''
      url     = 'https://' + host + path + format +  qs
      urlHTTP = 'http://'  + host + path + qs

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
      head['User-Agent'] = env['HTTP_USER_AGENT']

      fetch = -> url {
        begin
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
#        re.files R[Twitter + re.path + re.qs].indexTweets
#r.files R['https://www.reddit.com' + r.path + '.rss'].env(r.env).fetchFeed
# newPosts.concat ('file:'+body.localPath).R.indexFeed(:format => :feed, :base_uri => uri)
              body.writeFile resp
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

      # conditional update
      if priorMIME && (priorMIME.match?(MediaMIME) || priorMIME.match?(/javascript/) ||
                       %w{application/octet-stream text/css}.member?(priorMIME))
        #puts " HIT #{uri}"
      else
        begin # HTTPS
          fetch[url]
        rescue # HTTP
          fetch[urlHTTP]
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
        when 'js'
          [200, {'Content-Type' => 'application/javascript'}, ["console.log('hello #{host}#{path}');"]]
        else
          [200, {'Content-Type' => 'text/html'}, [htmlDocument]]
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
        [200, {'Content-Length' => 0}, []]
      end
    end
  end
end
