#watch __FILE__
class R

  Apache = ENV['apache'] # apache=true in shell-environment
  Nginx  = ENV['nginx']

  def env r=nil
    r ? (@r = r; self) : @r
  end

  def R.call e
    e.extend Th # HTTP utility functions
    dev         # watched files
    e['HTTP_X_FORWARDED_HOST'].do{|h| e['SERVER_NAME'] = h }
    path = CGI.unescape e['REQUEST_PATH'].force_encoding('UTF-8').gsub '+','%2B'
    resource = R['http://'+e['SERVER_NAME']+path]
    resource.inside ? (
      e['uri'] = resource.uri
      resource.env(e).send e['REQUEST_METHOD']) : [403,{},[]]
  rescue Exception => x
    E500[x,e]
  end

  def q; @r.q end

  E404 = -> e,r,g=nil {
    g ||= {} # graph
    s = g[e.uri] ||= {} # resource
    path = e.pathSegment
    s[Title] = '404'
    s[RDFs+'seeAlso'] = [e.parent, path.a('*').glob, e.a('*').glob] unless path.to_s == '/'
    s['#query'] = Hash[r.q.map{|k,v|[k.to_s.hrefs,v.to_s.hrefs]}]
    s[Header+'accept'] = r.accept
    %w{CHARSET LANGUAGE ENCODING}.map{|a| s[Header+'accept-'+a.downcase] = r.accept_('_'+a)}
    r.map{|k,v| s[Header+k.sub(/^HTTP_/,'').downcase.gsub('_','-')] = v }
    r.q.delete 'view' unless r.q['view']=='edit'
    [404,{'Content-Type'=> r.format},[Render[r.format][g,r]]]}

  Errors = {}

  GET['/500'] = -> e,r { 
    r['ETag'] = Errors.keys.sort.h
    e.condResponse r.format, ->{Render[r.format][Errors, r]}}

  E500 = -> x,e {
    uri = 'http://'+e['SERVER_NAME']+e['REQUEST_URI']
    $stderr.puts [500, uri, x.class, x.message].join ' '
    Errors[e['uri']] ||= {'uri' => uri, Content => [x.class, x.message,x.backtrace[0..2]].flatten.join('<br>')}

    [500,{'Content-Type'=>'text/html'},
     [H[{_: :html,
          c: [{_: :head,c: [{_: :title, c: 500},(H.css '/css/500')]},
              {_: :body,
                c: [{_: :h1, c: 500},
                    {_: :table,
                      c: [{_: :tr,c: [{_: :td, c: {_: :b, c: x.class}},{_: :td, class: :space},{_: :td, class: :message, c: x.message.hrefs}]},
                          x.backtrace.map{|f| p = f.split /:/, 3
                            {_: :tr,
                              c: [{_: :td, class: :path, c: p[0].abbrURI},
                                  {_: :td, class: :index, c: p[1]},
                                  {_: :td, class: :context, c: (p[2]||'').hrefs}].cr}}.cr]}]}]}]]]}
  def OPTIONS
    [200,
     {'Access-Control-Allow-Methods' => 'GET, PUT, POST, OPTIONS, HEAD, MKCOL, DELETE, PATCH',
       'Access-Control-Allow-Origin' => '*',
       'Allow' => 'GET, PUT, POST, OPTIONS, HEAD, MKCOL, DELETE, PATCH',
       'Accept-Patch' => 'application/json',
       'Accept-Post' => 'text/turtle;charset=utf-8,text/n3;charset=utf-8,text/nt;charset=utf-8,text/css;charset=utf-8,text/html;charset=utf-8,text/javascript;charset=utf-8,text/plain;charset=utf-8,application/rdf+xml;charset=utf-8,application/json;charset=utf-8,image/jpeg,image/jpeg,image/png,image/gif,font/otf',
     },
     []]
  end

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
    {
      '.atom' => 'application/atom+xml',
      '.html' => 'text/html',
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
        return mime if R::Render[mime]}} # available renderer

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
