#!/usr/bin/env ruby
require 'ww'
'https://www.reddit.com/r/boston+roxbury+dorchester+massachusetts+bostonmusic/new/.rss?sort=new'.R.getFeed
'https://twitter.com/search?f=tweets&vertical=default&q=@universalhub'.R.indexTweets
'.conf/boston.tw'.R.fetchTweets