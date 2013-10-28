#watch __FILE__
require 'rack'
%w{GET HEAD POST PATCH perf uid util 404 500}.map{|i|require_relative 'Th/' + i}

class E

  def E.call e
    dev
    e.extend Th
    e['HTTP_X_FORWARDED_HOST'].do{|h| e['SERVER_NAME'] = h }
    p = e['REQUEST_PATH'].force_encoding 'UTF-8'

    uri = CGI.unescape(if (p.index Prefix) == 0
                         p[Prefix.size..-1]
                       else
                         'http://' + e['SERVER_NAME'] + (p.gsub '+','%2B')
                       end).E.env e
    
    if (uri.node.expand_path.to_s.index FSbase) == 0
      e['uri'] = uri.uri
      # response
      r = nil              # request method
      b = Benchmark.measure{ r = uri.send e.fn }
      F['log'][r[0],e,b.real]
      r
    else
      [403,{},['Forbidden']]
    end

  rescue Exception => x
    $stderr.puts 500, e['REQUEST_URI'] ,x.message,x.backtrace
    F['log'][500,e]
    F['E500'][x,@r]
  end

end
