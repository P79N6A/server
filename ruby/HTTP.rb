#watch __FILE__
class E

  def E.call e
    e.extend Th # add HTTP utility functions to environment table
    dev # see if watched files were changed
    e['HTTP_X_FORWARDED_HOST'].do{|h| e['SERVER_NAME'] = h }
    path = CGI.unescape e['REQUEST_PATH'].force_encoding('UTF-8').gsub '+','%2B'
    resource = E['http://'+e['SERVER_NAME']+path]

    if resource.inside
      e['uri'] = resource.uri
      (resource.env e).send e['REQUEST_METHOD']
    else
      [403,{},[]]
    end

  rescue Exception => x
    F['E500'][x,e]
  end

end

module Th

  # Query-String -> Hash
  def q
    @q ||=
      (if q = self['QUERY_STRING']
         h = {}
         q.split(/&/).map{|e| k,v = e.split(/=/,2).map{|x| CGI.unescape x }
                              h[k] = v }
         h
       else
         {}
       end)
  end

  # Accept -> Hash
  def accept_ k=''
    d={}
    self['HTTP_ACCEPT'+k].do{|k|
      (k.split /,/).map{|e| # each pair
        f,q = e.split /;/   # split MIME from q value
        i = q && q.split(/=/)[1].to_f || 1.0
        d[i] ||= []; d[i].push f.strip}} # append
    d
  end

  def format
    @format ||= conneg
  end

  def conneg
    # specific format-variant URI
    { '.html' => 'text/html',
      '.jsonld' => 'application/ld+json',
      '.nt' => 'text/ntriples',
      '.n3' => 'text/n3',
      '.ttl' => 'text/turtle',
    }[File.extname self['uri']].do{|mime|
      return mime}

    # Accept formats
    accept.sort.reverse.map{|q,mimes|
      mimes.map{|mime|
        return mime if E::F[E::Render+mime]}}
    'text/html'
  end

  def accept; @accept ||= accept_ end

end

class Hash

  # Hash -> Query-String
  def qs
   '?'+map{|k,v|k.to_s+'='+(v ? (CGI.escape [*v][0].to_s) : '')}.intersperse("&").join('')
  end

  def env 
    @r = r
    self
  end

end
