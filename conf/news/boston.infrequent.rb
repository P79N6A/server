#!/usr/bin/env ruby
require 'ww/constants'
host = ARGV[0]
 src = Pathname.new(File.expand_path File.dirname __FILE__).relative_path_from(Pathname.new `pwd`.chomp).to_s

(src+'/boston.infrequent.u').R.getFeeds host
