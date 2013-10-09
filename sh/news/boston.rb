#!/usr/bin/env ruby
require 'infod'

unless h = ARGV[0]
  puts "missing hostname arg"
  exit  
end

'/sh/news/boston.u'.E.uris.tail.
  map{|u|u.getFeed h}
