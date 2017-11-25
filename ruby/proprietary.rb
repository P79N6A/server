class R

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

end
