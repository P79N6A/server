#!/usr/bin/env ruby
require 'infod'
h = ARGV[0]
(puts "hostname arg";exit) unless h

'/sh/news/radio.tw'.E.tw h
'/sh/news/radio.u'.E.uris.tail.map{|u|u.getFeed h}
