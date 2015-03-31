# coding: utf-8
#watch __FILE__

module Rack
  module Adapter
    def self.guess _; :rack end
    def self.load _
      Rack::Builder.new { # also in httpd.ru for eg. argument to unicorn
        use Rack::Deflater
        run R
      }.to_app
    end
  end
end

class R

  # help debug-output through thin/foreman shell-buffering a bit
  $stdout.sync = true
  $stderr.sync = true

  def R.dev # scan watched-files for changes
    Watch.each{|f,ts|
      if ts < File.mtime(f)
        load f
      end }
  end

  def R.call e
    method = e['REQUEST_METHOD']
    return [405, {'Allow' => Allow},[]] unless AllowMethods.member? method
    e.extend Th # environment util-functions
    dev         # check for updated source-code
    e['HTTP_X_FORWARDED_HOST'].do{|h|e['SERVER_NAME']=h} # canonical hostname
    e['SERVER_NAME'] = e.host.gsub /[\.\/]+/, '.'        # clean hostname
    rawpath = URI.unescape(e['REQUEST_PATH'].utf8).gsub(/\/+/,'/') rescue '/' # clean path
    path = Pathname.new(rawpath).expand_path.to_s        # interpret path
    path += '/' if path[-1] != '/' && rawpath[-1] == '/' # preserve trailing-slash
    resource = R[e.scheme + "://" + e.host + path]       # resource instance
    e['uri'] = resource.uri                              # canonical URI to environment
    e[:Links] = {}; e[:Response] = {}; e[:filters] = []  # init request-variables
#    puts e.to_a.concat(e.q.to_a).map{|k,v|[k,v].join "\t"} # verbose-log request
    resource.setEnv(e).send(method).do{|s,h,b| # call into request and inspect response
      R.log e,s,h,b # log response
      [s,h,b]} # return response
  rescue Exception => x
    E500[x,e]
  end

  def R.log e, s, h, b
    Stats[:status][s] ||= 0
    Stats[:status][s] += 1
    Stats[:host][e.host] ||= 0
    Stats[:host][e.host] += 1
    mime = nil
    h['Content-Type'].do{|ct|
      mime = ct.split(';')[0]
      Stats[:format][mime] ||= 0
      Stats[:format][mime] += 1}
    puts [e['REQUEST_METHOD'], s,
          [e.scheme, '://', e.host, e['REQUEST_URI']].join,
          h['Location'] ? ['->',h['Location']] : nil, '<'+e.user+'>',
          e['HTTP_REFERER']].
          flatten.compact.map(&:to_s).map(&:to_utf8).join ' '
  end

  GET['/ERROR'] = -> d,e {0/0}
  GET['/ERROR/ID'] = -> d,e {
    uri = d.path
    graph = {uri => Errors[uri]}
    [200,{'Content-Type' => e.format},
     [Render[e.format].do{|p|p[graph,e]} || graph.toRDF.dump(RDF::Writer.for(:content_type => e.format).to_sym)]]}

  E404 = -> resource, env, graph=nil {
    ENV2RDF[env, graph||={}]
    [404,{'Content-Type' => env.format},
     [Render[env.format].do{|fn|fn[graph,env]} ||
      graph.toRDF.dump(RDF::Writer.for(:content_type => env.format).to_sym, :prefixes => Prefixes)]]}

  E500 = -> x,e {
    ENV2RDF[e,graph={}]
    errorURI = '/ERROR/ID/' + e.uri.h
    title = [x.class, x.message.noHTML].join ' '
    bt = '<pre><h2>stack</h2>' + x.backtrace.join("\n").noHTML + '</pre>'
    error = graph[e.uri]
    error[Title] = title
    error[Content] = bt
    Errors[errorURI] = error

    Stats[:status][500] ||= 0
    Stats[:status][500]  += 1
    Stats[:error][errorURI]||= 0
    Stats[:error][errorURI] += 1

    $stderr.puts [500, e.uri, title].join ' '
    [500,{'Content-Type' => e.format},
     [Render[e.format].do{|p|p[graph,e]} ||
      graph.toRDF.dump(RDF::Writer.for(:content_type => e.format).to_sym)]]}

  ViewGroup[LDP+'Resource'] = -> g,env {
    paged = g.values.find{|r|r[Next] || r[Prev]}
    [H.css('/css/page', true), (H.js('/js/pager', true) if paged),
    (if env.signedIn
     uid = env.user.uri
     {_: :a, class: :user, href: uid, title: uid}
    else
      href = if env.scheme == 'http'
               'https://' + env.host + env['REQUEST_URI']
             else
               '/whoami'
             end
      {_: :a, class: :identify, href: href}
     end),
    g.map{|u,r|ViewA[LDP+'Resource'][r,env]}]}

  ViewA[LDP+'Resource'] = -> u,e {
    label = -> r {(r.R.query_values.do{|q|q['offset']} || r).R.stripDoc.path.gsub('/',' ')}
    prev = u[Prev]
    nexd = u[Next]
    [Prev,Next,Type].map{|p|u.delete p}
    [prev.do{|p|
       {_: :a, rel: :prev, href: p.uri, c: ['&larr; ', label[p]], title: '↩ previous page'}},
     nexd.do{|n|
       {_: :a, rel: :next, href: n.uri, c: [label[n], ' →'], title: 'next page →'}},
    (ViewA[Resource][u,e] unless u.keys.size==1)]}

  GET['/stat'] = -> e,r { g = {}
    r.q['sort'] ||= 'stat:size'

    Stats.map{|sym, table|
      group = e.uri + '#' + sym.to_s
      g[group] = {'uri' => group,
                  Type => R[Container], Label => sym.to_s,
                  LDP+'contains' => table.map{|key, count|
                    uri = case sym
                          when :error
                            key
                          when :host
                            r.scheme + "://" + key + '/'
                          when :format
                            'http://www.iana.org/assignments/media-types/' + key
                          when :status
                            W3 + '2011/http-statusCodes#' + key.to_s
                          else
                            e.uri + '#' + rand.to_s.h
                          end
                  {'uri' => uri, Title => key, Stat+'size' => count }}}}

    # enumerate schemes
    https =  r.scheme[-1]=='s'
    g['#scheme'] = {'uri' => '#scheme', Type => R[Container],
                    LDP+'contains' => [
                      {'uri' => r.scheme + "://" + r.host + '/stat',
                       Title => r.scheme,
                       Size => Stats[:status].values.inject(0){|s,v|s+v}
                      },
                      {'uri' => (https ? 'http' : 'https') + "://" + r.host + '/stat',
                       Title => https ? 'http' : 'https',
                       Size => 0 }]}

    # free space
    g['#storage'] = {
         Type => R[Resource],
      Content => ['<pre>',
                  `df -TBM -x tmpfs -x devtmpfs`,
                  '</pre>']}

    # render
    [200,{'Content-Type' => r.format}, [Render[r.format].do{|p|p[g,r]} ||
      g.toRDF.dump(RDF::Writer.for(:content_type => r.format).to_sym)]]}

  ENV2RDF = -> env, graph { # environment -> graph
    # request resource
    subj = graph[env.uri] ||= {'uri' => env.uri, Type => R[Resource]}

    # headers
   links = env.delete :Links
    resp = env.delete :Response
    [env,links,resp].compact.map{|fields|
      fields.map{|k,v|
        subj[HTTP+k.to_s.sub(/^HTTP_/,'')] = v.to_s.hrefs}}

    # derived fields
    subj['#query-string'] = Hash[env.q.map{|k,v|[k.to_s.hrefs,v.to_s.hrefs]}]
    subj['#accept'] = env.accept
    %w{CHARSET LANGUAGE ENCODING}.map{|a|
      subj['#accept-'+a.downcase] = env.accept_('_'+a)}}

  def q; @r.q end

end

module Th

  def SSLupgrade; [301,{'Location' => "https://" + host + self['REQUEST_URI']},[]] end

  def q # parse query-string
    @q ||=
      (if q = self['QUERY_STRING']
         h = {}
         q.split(/&/).map{|e| k, v = e.split(/=/,2).map{|x| CGI.unescape x }
                              h[k] = v }
         h
       else
         {}
       end)
  end

end

class Hash
  def qs # serialize to query-string
   '?'+map{|k,v|k.to_s+'='+(v ? (CGI.escape [*v][0].to_s) : '')}.intersperse("&").join('')
  end
end
