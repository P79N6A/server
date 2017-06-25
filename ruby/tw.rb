#!/usr/bin/env ruby
require 'ww'
class R

  def indexTweets
    graph = {}
    triplrTwitter do |s,p,o|
      graph[s] ||= {'uri' => s}
      graph[s][p] ||= []
      graph[s][p].push o
    end
    graph.map{|u,r|
      r[Date].do{|t|
          slug = (u.sub(/https?:\/\//,'.').gsub(/\W/,'.')).gsub /\.+/,'.'
          time = t[0].to_s.gsub(/[-T]/,'/').sub(':','/').sub /(.00.00|Z)$/, ''
          doc = "/#{time}#{slug}.e".R
          unless doc.e
            doc.writeFile({u => r}.to_json)
            puts "+ " + doc
          end}}
  end

  def triplrTwitter
    base = 'https://twitter.com'
    nokogiri.css('div.tweet > div.content').map{|t|
      s = base + t.css('.js-permalink').attr('href') # subject URI
      author = R[base+'/'+t.css('.username b')[0].inner_text]
      yield s, Type, R[SIOC+'Tweet']
      yield s, Date, Time.at(t.css('[data-time]')[0].attr('data-time').to_i).iso8601
      yield s, Creator, author
      content = t.css('.tweet-text')[0]
      content.css('a').map{|a| # resolve paths with remote base
        a.set_attribute('href',base + (a.attr 'href')) if (a.attr 'href').match /^\//
        yield s, DC+'link', R[a.attr 'href']
      }
      yield s, Content, StripHTML[content.inner_html].gsub(/<\/?span[^>]*>/,'').gsub(/\n/,'').gsub(/\s+/,' ')}
  end


end

'twits'.R.node.readlines.shuffle.each_slice(22){|s|R['https://twitter.com/search?f=realtime&q='+s.map{|u|'from:'+u.chomp}.intersperse('+OR+').join].indexTweets}
