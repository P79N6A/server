#!/usr/bin/env ruby
require 'ww/constants'
hostname = ARGV[0]
src = Pathname.new File.expand_path File.dirname __FILE__   # script location
rel = src.relative_path_from(Pathname.new `pwd`.chomp).to_s # path to scripts
R(rel+'/boston.tw').tw hostname
'http://www.reddit.com/r/boston+cambridgema+eastie+roxbury+somerville/new/.rss?sort=new'.R.getFeed hostname

