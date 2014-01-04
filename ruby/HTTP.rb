watch __FILE__
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

  # default "protograph" identity and resource thunks
  fn 'protograph/',->e,q,g{
    set = (q['set'] && F['set/'+q['set']] || F['set/'])[e,q,g]
    unless set.empty?
      g['#'] = {RDFs+'member' => set, DC+'hasFormat' => %w{text/n3}.map{|m|E('http://'+e.env['SERVER_NAME']+e.env['REQUEST_PATH']+'?format='+m)}.compact}
      set.map{|u| g[u.uri] = u }
    end
    F['docsID'][g,q]}

  # default graph (filesystem store)
  # to change default graph-construction fn,
  # define GET handler w/ set-env: q['graph'] = 'hexastore' (or rewrite this function)
  fn 'graph/',->e,q,m{
    # force thunks
    m.values.map{|r|(r.env e.env).graphFromFile m if r.class == E }
    # cleanup thunks that didn't expand
    m.delete_if{|u,r|r.class==E}}

  # document-set for base protograph
  fn 'set/',->e,q,g{
    s = []
    s.concat e.docs
    e.pathSegment.do{|p| s.concat p.docs }
    s }

  # unique ID for a resource-set
  fn 'docsID',->g,q{
    puts [:docs,*g.sort.map{|u,r|[u, r.respond_to?(:m) && r.m].join ' '}].join "\n"
   [q.has_key?('nocache').do{|_|rand},
     g.sort.map{|u,r|
       [u, r.respond_to?(:m) && r.m]}].h
  }

  def response

    q = @r.q       # query-string
    g = q['graph'] # graph-function selector

    # empty response graph
    m = {}

    # identify graph
    graphID = (g && F['protograph/' + g] || F['protograph/'])[self,q,m]

    return F[E404][self,@r] if m.empty?

    # identify response
    @r['ETag'] ||= [graphID, @r.format, Watch].h

    maybeSend @r.format, ->{
      
      # response
      r = E'/E/req/' + @r['ETag'].dive
      if r.e # response exists
        r    # cached response
      else
        
        # graph
        c = E '/E/graph/' + graphID.dive
        if c.e # graph exists
          m.merge! c.r true
        else
          # construct graph
          (g && F['graph/' + g] || F['graph/'])[self,q,m]
          # cache graph
          c.w m,true
        end

        # graph sort/filter
        E.filter q, m, self

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
    [200,{'Content-Type'=>'text/html; charset=utf-8'},
     [self]]
  end

end

module Th

  # raw query-string content
  def qs
    (['GET','HEAD'].member? verb) ? self['QUERY_STRING'] : self['rack.input'].read
  end

  # memoize parsed query-string
  def q
    @q ||= (qs||'').qp.do{|q|
      (q['?']).do{|d|
        E::F['?'][d].do{|g| # expand aliases
          g.merge q
        } || q } || q}
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

  # generate querystring
  def qs
   '?'+map{|k,v|k.to_s+'='+(v ? (CGI.escape [*v][0].to_s) : '')}.intersperse("&").join('')
  end

  def env r # attach environment variable
    @r = r
    self
  end

end
