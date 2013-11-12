#!/usr/bin/env ruby
require 'infod'
h = ARGV[0]
(puts "hostname arg";exit) unless h

'/sh/news/marmot.tw'.E.tw h
'/sh/news/marmot.u'.E.uris.tail.map{|u|u.getFeed h}
'http://www.reddit.com/r/vietnam+japan+korea+china+malaysia+cambodia+laos/new/.rss?sort=new'.E.getFeedReddit h
