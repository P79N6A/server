#!/usr/bin/env ruby
require 'ww'
host = ARGV[0]

# container-path of feed-list
src = Pathname.new(File.expand_path File.dirname __FILE__).relative_path_from(Pathname.new `pwd`.chomp).to_s

# ingest
(src+'/boston.u').R.getFeeds host
