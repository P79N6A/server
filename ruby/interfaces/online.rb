class R

  # interface with some online services
  # READ-ONLY access on remote

  Twitter = 'https://twitter.com'
  def fetchTweets
    nokogiri.css('div.tweet > div.content').map{|t|
      s = Twitter + t.css('.js-permalink').attr('href')
      authorName = t.css('.username b')[0].inner_text
      author = R[Twitter + '/' + authorName]
      ts = Time.at(t.css('[data-time]')[0].attr('data-time').to_i).iso8601
      yield s, Type, R[SIOC+'Tweet']
      yield s, Date, ts
      yield s, Creator, author
      yield s, To, (Twitter + '/#twitter').R
      yield s, Label, authorName
      content = t.css('.tweet-text')[0]
      content.css('a').map{|a|
        a.set_attribute('href', Twitter + (a.attr 'href')) if (a.attr 'href').match /^\//
        yield s, DC+'link', R[a.attr 'href']}
      yield s, Abstract, StripHTML[content.inner_html].gsub(/<\/?span[^>]*>/,'').gsub(/\n/,'').gsub(/\s+/,' ')}
  end
  def indexTweets
    graph = {}
    # build graph
    fetchTweets{|s,p,o|
      graph[s] ||= {'uri'=>s}
      graph[s][p] ||= []
      graph[s][p].push o}
    # serialize tweets to file(s)
    graph.map{|u,r|
      r[Date].do{|t|
        slug = (u.sub(/https?/,'.').gsub(/\W/,'.')).gsub /\.+/,'.'
        time = t[0].to_s.gsub(/[-T]/,'/').sub(':','/').sub /(.00.00|Z)$/, ''
        doc = "/#{time}#{slug}.e".R
        unless doc.e
          puts u
          doc.writeFile({u => r}.to_json)
        end}}
  end
  def twitter
    open(pathPOSIX).readlines.map(&:chomp).shuffle.each_slice(16){|s|
      readURI = Twitter + '/search?f=tweets&vertical=default&q=' + s.map{|u|'from:'+u.chomp}.intersperse('+OR+').join
      readURI.R.indexTweets}
  end

  Instagram = 'https://www.instagram.com/'
  def ig
    open(pathPOSIX).readlines.map(&:chomp).map{|ig|
      R[Instagram+ig].indexInstagram}
  end

  def feeds; puts (nokogiri.css 'link[rel=alternate]').map{|u|join u.attr :href} end

  def fetchFeed
    head = {} # request header
    cache = R['/.cache/'+uri.sha2+'/'] # storage
    etag = cache + 'etag'      # cache etag URI
    priorEtag = nil            # cache etag value
    mtime = cache + 'mtime'    # cache mtime URI
    priorMtime = nil           # cache mtime value
    body = cache + 'body.atom' # cache body URI
    if etag.e
      priorEtag = etag.readFile
      head["If-None-Match"] = priorEtag unless priorEtag.empty?
    elsif mtime.e
      priorMtime = mtime.readFile.to_time
      head["If-Modified-Since"] = priorMtime.httpdate
    end
    begin # conditional GET
      open(uri, head) do |response|
        curEtag = response.meta['etag']
        curMtime = response.last_modified || Time.now rescue Time.now
        etag.writeFile curEtag if curEtag && !curEtag.empty? && curEtag != priorEtag # new ETag value
        mtime.writeFile curMtime.iso8601 if curMtime != priorMtime # new Last-Modified value
        resp = response.read
        unless body.e && body.readFile == resp
          body.writeFile resp # new cached body
          ('file:'+body.pathPOSIX).R.indexFeed :format => :feed, :base_uri => uri # run indexer
        end
      end
    rescue OpenURI::HTTPError => error
      msg = error.message
      puts [uri,msg].join("\t") unless msg.match(/304/)
    end
  rescue Exception => e
    puts uri, e.class, e.message
  end
  def fetchFeeds; open(pathPOSIX).readlines.map(&:chomp).map(&:R).map(&:fetchFeed) end

  alias_method :getFeed, :fetchFeed

  def indexFeed options = {}
    g = RDF::Repository.load self, options
    g.each_graph.map{|graph|
      graph.query(RDF::Query::Pattern.new(:s,R[R::Date],:o)).first_value.do{|t| # find timestamp
        time = t.gsub(/[-T]/,'/').sub(':','/').sub /(.00.00|Z)$/, ''
        slug = (graph.name.to_s.sub(/https?:\/\//,'.').gsub(/[\W_]/,'..').sub(/\d{12,}/,'')+'.').gsub(/\.+/,'.')[0..127].sub(/\.$/,'')
        doc =  R["/#{time}#{slug}.ttl"]
        unless doc.e
          doc.dir.mkdir
          cacheBase = doc.stripDoc
          graph << RDF::Statement.new(graph.name, R[DC+'cache'], cacheBase)
          RDF::Writer.open(doc.pathPOSIX){|f|f << graph}
          puts cacheBase
        end
        true}}
    self
  rescue Exception => e
    puts uri, e.class, e.message
  end

end
