require_relative 'constants'
class R

  Apache = ENV['apache'] # apache=true in shell-environment
  Nginx  = ENV['nginx']

  def env r=nil
    r ? (@r = r; self) : @r
  end

  def R.call e
    e.extend Th # HTTP utility functions
    dev         # watched files changed?
    e['HTTP_X_FORWARDED_HOST'].do{|h| e['SERVER_NAME'] = h }
    path = CGI.unescape e['REQUEST_PATH'].force_encoding('UTF-8').gsub '+','%2B'
    resource = R['http://'+e['SERVER_NAME']+path]
    resource.inside ? (
      e['uri'] = resource.uri
      (resource.env e).send e['REQUEST_METHOD']) : [403,{},[]]
  rescue Exception => x
    F[500][x,e]
  end

  def q; @r.q end

end

module Th

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

    # URI of format-variant
    { '.html' => 'text/html',
      '.jsonld' => 'application/ld+json',
      '.nt' => 'text/ntriples',
      '.n3' => 'text/n3',
      '.rdf' => 'application/rdf+xml',
      '.ttl' => 'text/turtle',
      '.txt' => 'text/plain',
    }[File.extname self['uri']].do{|mime|
      return mime}

    # Accept values
    accept.sort.reverse.map{|q,mimes| # sort on descending q-value
      mimes.map{|mime|
        return mime if R::F[R::Render+mime]}} # available renderer

    'text/html'
  end

  def accept; @accept ||= accept_ end

end

class Hash

  def qs
   '?'+map{|k,v|k.to_s+'='+(v ? (CGI.escape [*v][0].to_s) : '')}.intersperse("&").join('')
  end

  def env 
    @r = r
    self
  end

end
