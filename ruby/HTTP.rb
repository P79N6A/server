require 'rack'

class E

  def E.call e
    dev
    e.extend Th
    e['HTTP_X_FORWARDED_HOST'].do{|h| e['SERVER_NAME'] = h }
    p = e['REQUEST_PATH'].force_encoding 'UTF-8'

    uri = CGI.unescape((p.index(URIURL) == 0) ? p[URIURL.size..-1] : ('http://'+e['SERVER_NAME']+(p.gsub '+','%2B'))).E.env e

    uri.inside ? ( e['uri'] = uri.uri
                   uri.send e.verb ) : [403,{},[]]

  rescue Exception => x
    F['E500'][x,e]
  end

end
