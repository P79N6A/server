class R

  E404 = -> e,r,g=nil {
    g ||= {}            # graph
    s = g[e.uri] ||= {} # resource
    path = e.justPath
    s[Title] = '404'
    s[RDFs+'seeAlso'] = [e.parentURI, path.a('*').glob, e.a('*').glob] unless path.to_s == '/'
    s['#query'] = Hash[r.q.map{|k,v|[k.to_s.hrefs,v.to_s.hrefs]}]
    s[Header+'accept'] = r.accept
    %w{CHARSET LANGUAGE ENCODING}.map{|a| s[Header+'accept-'+a.downcase] = r.accept_('_'+a)}
    r.map{|k,v|
      s[Header+k.to_s.sub(/^HTTP_/,'').downcase.gsub('_','-')] = v unless [:Links,:Response].member?(k)}
    r.q['view'] = 'HTML'
    [404,{'Content-Type'=> 'text/html'},[Render['text/html'][g,r]]]}

end
