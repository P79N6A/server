#!/usr/bin/env ruby
require 'ww'
# locate feed-list relative to caller, and fetch feeds
R[Pathname.new(File.expand_path File.dirname __FILE__).relative_path_from(Pathname.new `pwd`.chomp).to_s+'/boston.u'].fetchFeeds
