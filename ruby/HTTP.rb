#watch __FILE__
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

class String

  # querystring parse
  def qp
    d={}
    split(/&/).map{|e|
      k,v=e.split(/=/,2).map{|x|
         CGI.unescape x}
      d[k]=v}
    d
  end

  def hR
    [200, {'Content-Type'=>'text/html; charset=utf-8'}, [self]]
  end

end

module Th

  # query-string
  def qs
    (['GET','HEAD'].member? verb) ? self['QUERY_STRING'] : self['rack.input'].read
  end

  # parsed query-string
  def q
    @q ||= (qs||'').qp
  end

  # Accept header -> Hash
  def accept_ k=''
    d={}
    self['HTTP_ACCEPT'+k].do{|k|
      (k.split /,/).map{|e| # each pair
        f,q = e.split /;/   # split MIME from q value
        i = q && q.split(/=/)[1].to_f || 0.999
        d[i] ||= []; d[i].push f.strip}} # append
    d
  end

  def format
    @format ||= conneg
  end

  def conneg
    return 'text/html' if q.has_key?('view')
    # pathname extension
    {
      '.html' => 'text/html',
      '.jsonld' => 'application/ld+json',
      '.nt' => 'text/ntriples',
      '.n3' => 'text/n3',
      '.ttl' => 'text/turtle',
    }[File.extname self['uri']].do{|mime|
      return mime}

    # Accept header
    accept.sort.reverse.map{|q,mimes|
      mimes.map{|mime|
        return mime if E::F[E::Render+mime]}}
    'text/html'
  end

  def accept; @accept ||= accept_ end

  def verb
    self['REQUEST_METHOD']
  end

end

class Hash

  # unparse querystring
  def qs
   '?'+map{|k,v|k.to_s+'='+(v ? (CGI.escape [*v][0].to_s) : '')}.intersperse("&").join('')
  end

  def env 
    @r = r
    self
  end

end
