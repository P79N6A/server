#!/usr/bin/env ruby
require 'element/W'

unless h = ARGV[0]
  puts "missing hostname arg"
  exit  
end

uris = '/s/boston.u'.E.graph.keys.tail.map &:E

if ARGV[1]

  puts "checking URIs"
  r = uris.map{|u|
    r = `curl -Is "#{u}"`.lines.to_a[0].match(/\d{3}/)[0].to_i
    c = [r,u]
    puts c.join ' '
    c
  }

  puts "\n\n"

  r.map{|c|
    puts c.join(' ') unless c[0] == 200
  }

else

  uris.map{|u|u.getFeed h}

end
