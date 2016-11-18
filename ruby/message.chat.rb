#watch __FILE__
class R

  Abstract[SIOC+'InstantMessage'] = -> graph, msgs, e {
    # find unique log-files to summarize (could add stats here as we get a pass on raw messages)
    sources = {}
    msgs.map{|id,msg|
      source = msg[DC+'source'].justArray[0]
      sources[source.uri] ||= source
      graph.delete id # only visible when unsummarized
    }
    # link to HTML rewrite of log-file
    sources.map{|id,src|
      graph[id] = {'uri' => R[id+'.html'],
                   Type => R[Resource],
                   DC+'formatOf' => id.R
                  }
    }
  }
  ViewGroup[SIOC+'InstantMessage'] = ViewGroup[SIOC+'MicroblogPost'] = TabularView
  
  # IRC to RDF
  def triplrIRC &f
    i=-1 # line index

    day = dirname.split('/')[-3..-1].do{|dp| dp.join('-') if dp[0].match(/^\d{4}$/)}||''
    doc = uri.gsub '#','%23'
    channel = bare
    file = doc.R
    
    r.lines.map{|l|
      l.scan(/(\d\d):(\d\d) <[\s@]*([^\(>]+)[^>]*> (.*)/){|m|
        s = doc + '#' + (i+=1).to_s
        yield s, Date,day+'T'+m[0]+':'+m[1]+':00'
        yield s, SIOC+'channel', channel
        yield s, Creator, m[2]
        yield s, Label, m[2]
        yield s, Content, m[3].hrefs(true)
        yield s, Type, R[SIOC+'InstantMessage']
        yield s, DC+'source', file
      }
    }
  end

  def triplrTwitter
    base = 'https://twitter.com'
    nokogiri.css('div.tweet > div.content').map{|t|
      s = base + t.css('.js-permalink').attr('href') # subject URI
      yield s, Type, R[SIOC+'MicroblogPost']
      yield s, SIOC+'channel', 'twitter'
      yield s, Creator, R(base+'/'+t.css('.username b')[0].inner_text)

      yield s, Label, t.css('.fullname')[0].inner_text
      yield s, Date, Time.at(t.css('[data-time]')[0].attr('data-time').to_i).iso8601
      content = t.css('.tweet-text')[0]
      content.css('a').map{|a| # bind hostname to paths
        u = a.attr 'href'
        a.set_attribute('href',base + u) if u.match /^\//}
      yield s, Content, StripHTML[content.inner_html].gsub(/<\/?span[^>]*>/,'').gsub(/\n/,'').gsub(/\s+/,' ')}
  end
  def tw g
    node.readlines.shuffle.each_slice(22){|s|
      u = 'https://twitter.com/search?f=realtime&q='+s.map{|u|'from:'+u.chomp}.intersperse('+OR+').join
      u.R.twGET g}
  end

  def twGET g; triplrCache :triplrTwitter, g, nil, IndexFeedJSON end

end
