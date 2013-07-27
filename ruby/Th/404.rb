class E

  E404 = 'req/' + HTTP + '404'

  fn E404,->e,r{
    r[Type]=[(E HTTP+'404')]
    r['URI']=e.uri
    r['QUERY']=r.q
    r['ACCEPT']=r.accept
    r['SERVER_SOFTWARE']=Version
    %w{CHARSET LANGUAGE ENCODING}.map{|a|
      r['ACCEPT_'+a] = r.accept_ '_' + a }
 
   [404,{'Content-Type'=> 'text/html'},[H([H.css('/css/404'),r.html])]]}
  F['req/404']=F[E404]

  fn '/css/404.css/GET',->e,r{
    [200,{'Content-Type'=>'text/css'},
["body {background-color:#010;color:white; font-family: sans-serif}
a {background-color:#1f1;color:#000;text-decoration:none}
td.key {text-align:right}
td.key .frag {font-weight:bold;background-color:#ff0048;color:#000;padding-left:.2em;border-radius:.38em 0 0 .38em}
td.key .abbr {color:#eee;font-size:.92em}
td.val {border-style:dotted;border-width:0 0 .1em 0;border-color:#ff00c6}"]]}

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
