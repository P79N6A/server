# coding: utf-8
class WebResource
  module URIs
    Twitter = 'https://twitter.com'
  end
  module HTML
    Markup[InstantMessage] = -> msg, env {
      [{class: :msg,
        c: [msg[Date].map{|d|
              Markup[Date][d,env]}, ' ',
            msg[Creator].map{|c|
               Markup[Creator][c,env,msg.uri]}, ' ',
            msg[Abstract], ' <span>',
            msg[Content],  '</span>',
            msg[Image].map{|i|
              Markup[Image][i,env]},
            msg[Video].map{|v|
              Markup[Video][v,env]},
            msg[Link].map{|l|
              Markup[Link][l,env]}]},
       "<br>\n"]}

  end
  module HTTP

    Host['twitter.com'] = Host['mobile.twitter.com'] = Host['www.twitter.com'] = -> re {
      if re.path == '/'
        graph = {}
        # shuffle names into groups of 16
        open('.conf/twitter.com.bu'.R.localPath).readlines.map(&:chomp).shuffle.each_slice(16){|s|
          r = Twitter + '/search?f=tweets&vertical=default&q=' + s.map{|u|'from:'+u.chomp}.intersperse('+OR+').join
          graph[r] = {'uri' => r , Type => R[Resource]}}
        [200,{'Content-Type' => 'text/html'},[re.htmlDocument(graph)]]
      else
        re.files R[Twitter + re.path + re.qs].indexTweets
      end}

  end
  module Webize

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
        if content
          content.css('a').map{|a|
            a.set_attribute('id', 'tweetedlink'+rand.to_s.sha2)
            a.set_attribute('href', Twitter + (a.attr 'href')) if (a.attr 'href').match /^\//
            yield s, DC+'link', R[a.attr 'href']}
          yield s, Content, HTML.strip(content.inner_html).gsub(/<\/?span[^>]*>/,'').gsub(/\n/,'').gsub(/\s+/,' ')
        end}
    end

    def indexTweets
      newPosts = []
      graph = {}
      fetchTweets{|s,p,o|
        graph[s] ||= {'uri'=>s}
        graph[s][p] ||= []
        graph[s][p].push o}
      graph.map{|u,r| # visit tweet resource
        r[Date].do{|t|
          # find storage location
          slug = (u.sub(/https?/,'.').gsub(/\W/,'.')).gsub /\.+/,'.'
          time = t[0].to_s.gsub(/[-T]/,'/').sub(':','/').sub /(.00.00|Z)$/, ''
          doc = "/#{time}#{slug}.e".R
          if !doc.e # update cache
            doc.writeFile({u => r}.to_json)
            newPosts << doc
          end}}
      newPosts
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
        yield log, Date, mtime.iso8601
        yield log, Title, basename.split('%23')[-1] # channel
        yield log, Size, linenum
      end
    end
  end
end
