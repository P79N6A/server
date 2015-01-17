#!/usr/bin/env ruby
require 'ww/constants'
hostname = ARGV[0]
scriptDir = (Pathname.new File.expand_path File.dirname __FILE__).relative_path_from Pathname.new `pwd`.chomp
R[scriptDir.to_s + '/boston.tw'].tw hostname
'http://www.reddit.com/r/boston+bikeboston+SouthShore+massachusetts+roxbury+eastie+QuincyMA+WorcesterMA+providence+cambridgeMA+somerville/new/.rss?sort=new'.R.getFeed hostname
