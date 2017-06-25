#!/usr/bin/env ruby
require 'ww'
'http://www.inoreader.com/stream/user/1006464132/tag/YouTube%20Subscriptions'.R.getFeed
'https://www.reddit.com/r/boston+massachusetts+bikeboston/new/.rss?sort=new'.R.getFeed
'https://twitter.com/search?f=tweets&vertical=default&q=@universalhub'.R.indexTweets
'twits'.R.node.readlines.shuffle.each_slice(22){|s|R['https://twitter.com/search?f=realtime&q='+s.map{|u|'from:'+u.chomp}.intersperse('+OR+').join].indexTweets}
