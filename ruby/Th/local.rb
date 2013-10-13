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
  
  # webize PS(1)
  fn '/ps/GET',->e,r{
    [200,{'Content-Type'=>'text/plain'},[`ps aux`]]}

  # show response-codes for a list of URIs (.u)
  def checkURIs
    r = uris.select{|u|u.to_s.match /^http/}.map{|u|
      c = [`curl -IsA 404? "#{u}"`.lines.to_a[0].match(/\d{3}/)[0].to_i,u] # HEAD
     #c = [`curl -s -o /dev/null -w %{http_code} "#{u}"`.chomp.to_i,u] # GET
      puts c.join ' ' 
      c # status, uri tuple
    }
    puts "\n\n"
    r.map{|c|
      # show anomalies
      puts c.join(' ') unless c[0] == 200
    }
  end

end
