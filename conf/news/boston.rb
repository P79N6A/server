#!/usr/bin/env ruby
require 'ww'
hostname = ARGV[0]

# reddit
# fetch RSS/Atom version of http://www.reddit.com/r/boston+dorchester+bikeboston+massachusetts+roxbury+QuincyMA+providence/new/?sort=new
'http://www.reddit.com/r/boston+dorchester+bikeboston+massachusetts+roxbury+QuincyMA+providence/new/.rss?sort=new'.R.getFeed hostname

# twitter
scriptDir = (Pathname.new File.expand_path File.dirname __FILE__).relative_path_from Pathname.new `pwd`.chomp
R[scriptDir.to_s + '/boston.tw'].tw hostname
