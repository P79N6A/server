#!/usr/bin/env ruby
require 'ww'
# find feed-list - in same dir as this script - and fetch
R[Pathname.new(File.expand_path File.dirname __FILE__).relative_path_from(Pathname.new `pwd`.chomp).to_s+'/boston.u'].fetchFeeds # fetch blogs
