require 'rack'
%w{GET HEAD POST PATCH uid util 404 500}.map{|i|require_relative 'Th/' + i}

class E

  Prefix   = '/@'

  def E.call e
    dev         # check for changed source code
    e.extend Th # enable request-related utility functions
    e['HTTP_X_FORWARDED_HOST'].do{|h| e['SERVER_NAME'] = h }

    e['REQUEST_PATH'].force_encoding('UTF-8').do{|p|
      CGI.unescape(
      if (p.index Prefix) == 0 # non-local | non-HTTP URI
        p[Prefix.size..-1]
      else
        'http://'+e['SERVER_NAME']+p.gsub('+','%2B')
      end
    )}.E.env(e).do{|r|
      if (r.node.expand_path.to_s.index FSbase) == 0
        e['uri'] = r.uri
        r.send e.fn 
      else
        [403,{},['Forbidden']]
      end
    }.do{|r| puts [# inspect response
        e.fn, r[0],['http://', e['SERVER_NAME'], e['REQUEST_URI']].join,e['HTTP_USER_AGENT'],e['HTTP_REFERER']].join ' '
        r }
  rescue Exception => x
    $stderr.puts 500,x.message,x.backtrace
    F['500'][x,@r]
  end

end
