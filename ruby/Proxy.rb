class WebResource
  module HTTP

    %w{t.co bhne.ws bit.ly buff.ly bos.gl w.bos.gl dlvr.it ift.tt cfl.re nyti.ms t.umblr.com ti.me tinyurl.com trib.al ow.ly n.pr a.co youtu.be}.map{|host|Host[host] = Short}
    Host['.google.com'] = -> re {re.notfound}
    Host['reddit.com'] = Host['.reddit.com'] = -> re { re.files R['https://www.reddit.com' + re.path + '.rss'].fetchFeed }
    Path['twitter'] = -> re { graph = {} # shuffle names into groups of 16
      open('.conf/twitter.com.bu'.R.localPath).readlines.map(&:chomp).shuffle.each_slice(16){|s|
        r = Twitter + '/search?f=tweets&vertical=default&q=' + s.map{|u|'from:'+u.chomp}.intersperse('+OR+').join
        graph[r] = {'uri' => r, Link => r.R, Type => R[Resource]}}
      [200,{'Content-Type' => 'text/html'},[re.htmlDocument(graph)]]}
    Host['imgur.com'] = Host['*.imgur.com'] = -> re {
      if !re.ext.empty?
        if 'i.imgur.com' == re.host
          re.cache
        else
          [301,{'Location' => 'https://i.imgur.com' + re.path},[]]
        end
      else
        WrappedImage[re]
      end}
    Host['instagram.com'] = Host['.instagram.com'] = -> re {
      if re.parts[0] == 'p'
        WrappedImage[re]
      else
        graph = {}
        open('https://'+re.host+re.path).read.scan(/https:\/\/.*?jpg/){|f|
          unless f.match(/\/[sp]\d\d\dx\d\d\d\//)
            graph[f] = {'uri' => f, Type => R[Image], Image => f.R}
          end}
        [200,{'Content-Type' => 'text/html'},[re.htmlDocument(graph)]]
      end}

    def cache
      url     = 'https://' + host + path + qs
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
#        re.files R[Twitter + re.path + re.qs].indexTweets
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
      if priorMIME && (priorMIME.match?(MediaMIME) || priorMIME.match?(/javascript/) ||
                       %w{application/octet-stream text/css}.member?(priorMIME))
        puts " HIT #{uri}"
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
  end
end
