require 'rack'
%w{GET HEAD POST PATCH uid util 404 500}.map{|i|require_relative 'Th/' + i}

class E

  def E.call e
    dev         # check for changed source code
    e.extend Th # enable request-related utility functions
    e['HTTP_X_FORWARDED_HOST'].do{|h| e['SERVER_NAME'] = h } # hostname
   (e['REQUEST_PATH'].force_encoding('UTF-8').do{|u|         # path
      CGI.unescape(u.index(Prefix)==0 ? u[Prefix.size..-1] : # non-local|non-HTTP URI
      'http://' + e['SERVER_NAME'] + u.gsub('+','%2B'))      # HTTP URI
    }.E.env(e).jail.do{|r|           # valid path?
      e['uri']=r.uri; r.send e.fn    # update URI and continue
    } || [403,{},['invalid path']]). # reject
      do{|response| puts [           # inspect
        e.fn, response[0],['http://', e['SERVER_NAME'], e['REQUEST_URI']].join,e['HTTP_USER_AGENT'],e['HTTP_REFERER']].join ' '
        response }
    end

end
