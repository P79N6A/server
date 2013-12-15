class String
  # parse query-string
  def qp
    d={}
    split(/&/).map{|e|
      k,v=e.split(/=/,2).map{|x|
         CGI.unescape x}
      d[k]=v}
    d
  end
  # HTML response of string body
  def hR
    [200,{'Content-Type'=>'text/html; charset=utf-8'},
     [self]]
  end
end

module Th

  # unparsed query-string
  def qs
    (['GET','HEAD'].member? verb) ? self['QUERY_STRING'] : self['rack.input'].read
  end

  # memoize query
  def q
    @q ||= (qs||'').qp.do{|q|
      (q['?']).do{|d|
        E::F['?'][d].do{|g| # expand aliases
          g.merge q
        } || q } || q}
  end

  # Accept header
  def accept_ k=''
    d={}
    self['HTTP_ACCEPT'+k].do{|k|
      k.split(/,/).map{|e|
        f,q=e.split(/;/)
        i=q&&q.split(/=/)[1].to_f||1
        d[i]||=[]
        d[i].push f}}
    d
  end

  def format
    @format ||= conneg
  end

  def conneg
    # format in querystring
    return q['format'] if q['format'] && E::F[E::Render+q['format']]
    # format in Accept header
    accept.sort.reverse.map{|p|p[1].map{|mime|
     return mime if E::F[E::Render+mime]}}
    # default
    'text/html'
  end

  def accept; @accept ||= accept_ end

  def verb
    self['REQUEST_METHOD']
  end

end

class Hash

  def qs
   '?'+map{|k,v|k.to_s+'='+(v ? (CGI.escape [*v][0].to_s) : '')}.intersperse("&").join('')
  end

  def env r # attach environment variable
    @r = r
    self
  end

end

class E

  # request environment
  def env r=nil
    r ? (@r = r
         self) : @r
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
