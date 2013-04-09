#!/usr/bin/env ruby
require 'element/W'
ARGV[0].do{|h|
  puts "updating #{h}"
%w{ http://www.universalhub.com/node/feed/atom
    http://api.flickr.com/services/feeds/photos_public.gne?id=48232993@N00&lang=en-us&format=atom
    http://api.flickr.com/services/feeds/photos_public.gne?id=17702948@N06&lang=en-us&format=atom
    http://api.flickr.com/services/feeds/photos_public.gne?id=66169386@N04&lang=en-us&format=atom
    http://transportation.blog.state.ma.us/blog/atom.xml
    http://bostonbiker.org/feed/
    http://allston.tumblr.com/rss
    http://boston.eater.com/atom.xml
    http://abnewsflash.com/?feed=rss2
    http://allston02134.blogspot.com/atom.xml
    http://fuckyeahmassachusetts.tumblr.com/rss
    http://cityofbostonarchives.tumblr.com/rss
    http://feeds.feedburner.com/JamaicaPlainGazette
    http://misterching.tumblr.com/rss
    http://www.bpdnews.com/feed/atom/
    http://www.neponset.org/feed/
    http://feeds.boston.com/boston/yourtown/dorchester/rss
    http://bartlettevents.org/blog?format=rss
    http://www.tpdnews411.com/feeds/posts/default
    http://bostonrestaurants.blogspot.com/feeds/posts/default
    http://www.dotnews.com/rss.xml
    http://feeds.feedburner.com/BigRedShiny
    http://www.scidorchester.org/blog/feed
    http://api.flickr.com/services/feeds/photos_public.gne?id=93374791@N08&lang=en-us&format=atom
    http://www.wx1box.org/rss.xml
    }.map{|f|f.E.getFeed ARGV[0]} } || (puts "hostname needed")
