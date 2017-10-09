#!/usr/bin/env ruby
require 'ww'
'https://www.reddit.com/r/boston+roxbury+dorchester+massachusetts+bostonmusic/new/.rss?sort=new'.R.getFeed
'https://twitter.com/search?f=tweets&vertical=default&q=@universalhub'.R.indexTweets
'feeds/boston.tw'.R.node.readlines.shuffle.each_slice(22){|s|R['https://twitter.com/search?f=realtime&q='+s.map{|u|'from:'+u.chomp}.intersperse('+OR+').join].indexTweets}
