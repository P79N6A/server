#!/usr/bin/env ruby
require 'ww'
# fetch reddit
'https://www.reddit.com/r/boston+bikeboston+massachusetts/new/.rss?sort=new'.R.fetchFeed
# locate twitter-user list relative to caller, and fetch tweets
R[Pathname.new(File.expand_path File.dirname __FILE__).relative_path_from(Pathname.new `pwd`.chomp).to_s+'/boston.tw'].tw
