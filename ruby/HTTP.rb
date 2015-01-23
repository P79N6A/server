# coding: utf-8
#watch __FILE__
class R

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
    e['HTTP_X_FORWARDED_HOST'].do{|h|e['SERVER_NAME']=h}   # canonical hostname
    e['SERVER_NAME'] = e['SERVER_NAME'].gsub /[\.\/]+/,'.' # clean hostname
    rawpath = URI.unescape(e['REQUEST_PATH'].utf8).gsub(/\/+/,'/') rescue '/' # clean path
    path = Pathname.new(rawpath).expand_path.to_s          # interpret path
    path += '/' if path[-1] != '/' && rawpath[-1] == '/'   # preserve trailing-slash
    resource = R[e['rack.url_scheme']+"://"+e['SERVER_NAME']+path] # resource instance
    e['uri'] = resource.uri                                # canonical URI to environment
    e[:Links] = [] ; e[:Response] = {}                     # response metadata
#    puts e.to_a.concat(e.q.to_a).map{|k,v|[k,v].join "\t"} # log request
    resource.setEnv(e).send(method).do{|s,h,b| # call into request and inspect response
      R.log e,s,h,b # log response
      [s,h,b]} # return response
  rescue Exception => x
    E500[x,e]
  end

  def R.log e, s, h, b
    Stats[:status][s] ||= 0
    Stats[:status][s] += 1
    host = e['SERVER_NAME']
    Stats[:host][host] ||= 0
    Stats[:host][host] += 1
    mime = nil
    h['Content-Type'].do{|ct|
      mime = ct.split(';')[0]
      Stats[:format][mime] ||= 0
      Stats[:format][mime] += 1}
    puts [e.uri, '<'+e.user+'>', e['HTTP_REFERER']].compact.map(&:to_s).map(&:to_utf8).join ' '
  end

  E500 = -> x,e {
    error = {'uri' => e.uri,
             Title => [x.class, x.message].join(' '),
             Content => '<pre>' + x.backtrace.join("\n").noHTML + '<pre>'}
    graph = {e.uri => error}
    Stats[:status][500] ||= 0
    Stats[:status][500]  += 1
    Stats[:error][error]||= 0
    Stats[:error][error] += 1

    $stderr.puts [500, error[Title]]

    [500,{'Content-Type' => e.format},
     [Render[e.format].do{|p|p[graph,e]} ||
      graph.toRDF.dump(RDF::Writer.for(:content_type => e.format).to_sym)]]}

  ViewGroup[LDP+'Resource'] = -> g,env {
    paged = g.values.find{|r| r[Next] ||
                              r[Prev] }
    [H.css('/css/page', true),
     (H.js('/js/pager', true) if paged),
    ({_: :a, class: :up, href: Pathname.new(env['REQUEST_PATH']).parent, c: '&uarr;'} unless env['REQUEST_PATH'] == '/'),
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

  ServerInfo = -> e,r{   g = {}
    r.q['sort'] ||= 'stat:size'

    Stats.map{|sym, table|
      group = e.uri + '#' + sym.to_s
      g[group] = {'uri' => group,
                  Type => R[Container], Label => sym.to_s,
                  LDP+'contains' => table.map{|key, count|

                    uri = case sym
                          when :error
                            key.uri
                          when :host
                            r['rack.url_scheme'] + "://" + key + '/'
                          when :format
                            'http://www.iana.org/assignments/media-types/' + key
                          when :status
                            W3 + '2011/http-statusCodes#' + key.to_s
                          else
                            e.uri + '#' + rand.to_s.h
                          end

                    title = case sym
                            when :error
                              key[Title]
                            else
                              key
                            end

                    {'uri' => uri, Title => title, Stat+'size' => count }}}}

    g['#storage'] = {
         Type => R[Resource],
      Content => ['<pre>',
                  `df -TBM -x tmpfs -x devtmpfs`,
                  '</pre>']}

    [200,{'Content-Type' => r.format}, [Render[r.format].do{|p|p[g,r]} ||
      g.toRDF.dump(RDF::Writer.for(:content_type => r.format).to_sym)]]}

  E404 = -> e,r,g=nil {
    g ||= {}                                               # graph
    s = g[e.uri] ||= {'uri' => e.uri, Type => R[Resource]} # subject resource
    if r.format=='text/html'
      s['#query-string'] = Hash[r.q.map{|k,v|[k.to_s.hrefs,v.to_s.hrefs]}] # parsed qs
      s['#accept'] = r.accept
      %w{CHARSET LANGUAGE ENCODING}.map{|a| s['#accept-'+a.downcase] = r.accept_('_'+a)}
    else
      g.delete ''
      r.delete :Links
      r.delete :Response
    end
    r.map{|k,v|s[HTTP+k.to_s.sub(/^HTTP_/,'')] = v}        # headers -> graph
    [404,{'Content-Type' => r.format},[Render[r.format].do{|p|p[g,r]} ||
                                       g.toRDF.dump(RDF::Writer.for(:content_type => r.format).to_sym, :prefixes => Prefixes)]]}

end
