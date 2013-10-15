class E
# customize
puts "local.rb"  

  # for robots
  fn '/robots.txt/GET',->e,r{
  [200,{'Content-Type'=>'text/plain'},
["User-agent: *
Disallow: /E
Disallow: /.git
"]]}

end
