#!/usr/bin/env ruby
require 'ww'
'https://www.reddit.com/r/boston+bikeboston+massachusetts/new/.rss?sort=new'.R.fetchFeed # fetch reddit
R[Pathname.new(File.expand_path File.dirname __FILE__).relative_path_from(Pathname.new `pwd`.chomp).to_s+'/boston.tw'].tw # fetch twitter
