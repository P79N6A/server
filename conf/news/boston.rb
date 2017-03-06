#!/usr/bin/env ruby
require 'ww'
'http://www.reddit.com/r/boston+dorchester+bikeboston+massachusetts+roxbury+QuincyMA+providence/new/.rss?sort=new'.R.fetchFeed # fetch reddit
R[Pathname.new(File.expand_path File.dirname __FILE__).relative_path_from(Pathname.new `pwd`.chomp).to_s+'/boston.tw'].tw # fetch twitter
