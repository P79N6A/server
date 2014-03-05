#!/usr/bin/env ruby
require 'rrww/constants'

unless h = ARGV[0]
  puts "hostname arg missing"
  exit
end

'/news/boston.u'.R.uris.tail.map{|u|u.getFeed h}
