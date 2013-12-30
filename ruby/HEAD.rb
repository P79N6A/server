class E

  def HEAD
    self.GET.do{|s,h,b|[s,h,[]]}
  end

  def OPTIONS
    [200,{},[]]
  end

  # HEAD response-codes on a (.u) list of URIs
  def checkURIs
    r = uris.select{|u|u.to_s.match /^http/}.map{|u|
      c = [`curl -IsA 404? "#{u}"`.lines.to_a[0].match(/\d{3}/)[0].to_i,u] # HEAD
      puts c.join ' ' 
      c } # status, uri tuple
    puts "\n\n"
    r.map{|c|
      # show anomalies
      puts c.join(' ') unless c[0] == 200 }
  end

end
