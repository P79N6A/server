#!/usr/bin/env ruby
require 'ww'
hostname = ARGV[0]

# blogs are in *.infrequent.rb

# reddit
'http://www.reddit.com/r/boston+dorchester+bikeboston+massachusetts+roxbury+QuincyMA+providence/new/.rss?sort=new'.R.getFeed hostname

# twitter
# find relative path to user-list wherever this script is and you're running it from
scriptDir = (Pathname.new File.expand_path File.dirname __FILE__).relative_path_from Pathname.new `pwd`.chomp
R[scriptDir.to_s + '/boston.tw'].tw hostname
