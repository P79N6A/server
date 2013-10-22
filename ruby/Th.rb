require 'rack'
%w{GET HEAD POST PATCH uid util 404 500}.map{|i|require_relative 'Th/' + i}

class E

  Prefix   = '/@'

  F['log']=->c,e{
    $stdout.puts [e.fn,c,['http://', e['SERVER_NAME'], e['REQUEST_URI']].join,
                  e['HTTP_USER_AGENT'],e['HTTP_REFERER']].join ' '}

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
      r = uri.send e.fn 
      F['log'][r[0],e]
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
