# coding: utf-8
class WebResource
  module URIs
    Twitter = 'https://twitter.com'
  end
  module HTML
    Markup[InstantMessage] = -> msg, env {
      abbr = env['q'].has_key? 'h'
      [{c: [([msg[Date].map{|d| Markup[Date][d,env,11]},
              {class: :creator, c: msg[Creator].map{|c|Markup[Creator][c,env]}}, ' ',
              msg[Abstract], msg[Content]] unless abbr),
            msg[Image].map{|i| Markup[Image][i,env]},
            msg[Video].map{|v| Markup[Video][v,env]},
            msg[Link].map(&:R)
          ]},("<br>\n" unless abbr)]}

    Markup[SIOC+'ChatLog'] = Markup[Container]

  end
  module Webize

    def twitter
      open(localPath).readlines.map(&:chomp).shuffle.each_slice(16){|s|
        readURI = Twitter + '/search?f=tweets&vertical=default&q=' + s.map{|u|'from:'+u.chomp}.intersperse('+OR+').join
        readURI.R.indexTweets}
    end

    def fetchTweets
      nokogiri.css('div.tweet > div.content').map{|t|
        s = Twitter + t.css('.js-permalink').attr('href')
        authorName = t.css('.username b')[0].inner_text
        author = R[Twitter + '/' + authorName]
        ts = Time.at(t.css('[data-time]')[0].attr('data-time').to_i).iso8601
        yield s, Type, R[SIOC+'InstantMessage']
        yield s, Date, ts
        yield s, Creator, author
        content = t.css('.tweet-text')[0]
        content.css('a').map{|a|
          a.set_attribute('id', 'tweetedlink'+rand.to_s.sha2)
          a.set_attribute('href', Twitter + (a.attr 'href')) if (a.attr 'href').match /^\//
          yield s, DC+'link', R[a.attr 'href']}
        yield s, Abstract, HTML.strip(content.inner_html).gsub(/<\/?span[^>]*>/,'').gsub(/\n/,'').gsub(/\s+/,' ')}
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

    def triplrChatLog &f
      linenum = -1
      base = stripDoc
      dir = base.dir
      log = base.uri
      basename = base.basename
      channel = dir + '/' + basename
      day = dir.uri.match(/\/(\d{4}\/\d{2}\/\d{2})/).do{|d|d[1].gsub('/','-')}
      readFile.lines.map{|l|
        l.scan(/(\d\d)(\d\d)(\d\d)[\s+@]*([^\(\s]+)[\S]* (.*)/){|m|
          s = base + '#l' + (linenum += 1).to_s
          yield s, Type, R[SIOC+'InstantMessage']
          yield s, Creator, R['#'+m[3]]
          yield s, To, channel
          yield s, Content, '<span class="msgbody">' +
                         m[4].hrefs{|p,o|
                             yield s,p,o } +
                         '</span>'
          yield s, Date, day+'T'+m[0]+':'+m[1]+':'+m[2] if day}}
      # logfile
      if linenum > 0
        yield log, Type, R[SIOC+'ChatLog']
        yield log, Date, mtime.iso8601
        yield log, Title, basename.split('%23')[-1] # channel
        yield log, Size, linenum
      end
    end
  end
end
