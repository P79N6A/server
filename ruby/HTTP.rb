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

  def env r=nil
    r ? (@r = r
         self) : @r
  end

  def response

    m = {}

    # graph identity (model)
    g = @r.q['graph']
    graphID = (g && F['protograph/' + g] || F['protograph/'])[self,@r.q,m]

    return F[E404][self,@r] if m.empty?

    # response identity (view)
    @r['ETag'] ||= [%w{filter view}.map{|a| @r.q[a].do{|v| F[a + '/' + v] && v}}, graphID, @r.format, Watch].h

    maybeSend @r.format, ->{
      
      # response
      r = E'/E/req/' + @r['ETag'].dive
      if r.e # response exists
        r    # cached response
      else
        
        # graph
        c = E '/E/graph/' + graphID.dive
        if c.e # exists
          m = c.r true
        else
          # construct
          (g && F['graph/' + g] || F['graph/'])[self, @r.q,m]
          # cache
          c.w m,true
        end

        # deterministic filters
        E.filter @r.q, m, self

        # response
        r.w render @r.format, m, @r
      end }
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
    return q['format'] if q['format'] && E::F[E::Render+q['format']]
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

  # unparse querystring
  def qs
   '?'+map{|k,v|k.to_s+'='+(v ? (CGI.escape [*v][0].to_s) : '')}.intersperse("&").join('')
  end

  def env 
    @r = r
    self
  end

end
