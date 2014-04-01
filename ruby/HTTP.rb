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

  F[404]=->e,r{
   id = e.uri     # response URI
    g = {id=>{}}  # response graph
    s = g[id]     # resource pointer
   fn = r['REQUEST_METHOD']

    # request environment -> graph
r.map{|k,v| s[Header + k] = k == 'uri' ? v : [v] }
  %w{CHARSET LANGUAGE ENCODING}.map{|a|
    s[Header+'ACCEPT_'+a] = [r.accept_('_' + a)]}
       s[Header+'ACCEPT'] = [r.accept]
                  s[Type] = [R[HTTP+'Response']]
s[HTTP+'statusCodeValue'] = [404]
    s[Header+'HTTP_HOST'] = [R['http://' + s[Header+'HTTP_HOST'][0]]] if s[Header+'HTTP_HOST']
              s['#query'] = [r.q]
            s['#seeAlso'] = [e.parent,*e.a('*').glob]
              r.q['view'] = 404

    [404,{'Content-Type'=> r.format},[Render[r.format][g,r]]]}

  View[404] = -> d,e {
    [H.css('/css/404'),{_: :style, c: "a {background-color:#{R.cs}}"},
     d.html]}

#  F['/500/GET'] = -> d,e {1/0}

  F[500]=->x,e{ $stderr.puts [500, e['REQUEST_URI'], x.class, x.message].join ' '
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
