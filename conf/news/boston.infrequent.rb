#!/usr/bin/env ruby
require 'ww'
# find path to feed-list (in same dir as this script) from caller-location, and fetch enumerated feeds
R[Pathname.new(File.expand_path File.dirname __FILE__).relative_path_from(Pathname.new `pwd`.chomp).to_s+'/boston.u'].fetchFeeds # fetch blogs
