#!/usr/bin/env ruby
require 'infodaemon'

unless h = ARGV[0]
  puts "missing hostname arg"
  exit  
end

'/s/boston.u'.E.uris.tail.
  map{|u|u.getFeed h}
