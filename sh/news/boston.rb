#!/usr/bin/env ruby
require 'element/W'
unless h = ARGV[0]
  puts "missing hostname arg"
  exit  
end

'/s/boston.u'.E.graph.keys.tail.map{|u|u.E.getFeed h}
