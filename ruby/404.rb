class R

  E404 = -> e,r,g=nil {
    g ||= {}            # graph
    s = g[e.uri] ||= {} # request-resource

    s[Title] = '404'
    s[Edit] = R[e.docroot+'?edit']
    s[RDFs+'seeAlso'] = e.parentURI unless e.justPath.to_s == '/'
    s[Header+'query-string'] = Hash[r.q.map{|k,v|[k.to_s.hrefs,v.to_s.hrefs]}]
    s[Header+'accept'] = r.accept

  %w{CHARSET LANGUAGE ENCODING}.map{|a|
    s[Header+'accept-'+a.downcase] = r.accept_('_'+a)}

  r.map{|k,v|
    s[Header+k.to_s.sub(/^HTTP_/,'').downcase.gsub('_','-')] = v unless [:Links,:Response].member?(k)}

    %w{path-info referer request-path request-uri}.map{|p|
       k = Header + p
    s[k] = R[s[k]] if s[k]}

    r.q['view'] = 'HTML'
    [404,{'Content-Type'=> 'text/html'},[Render['text/html'][g,r]]]}

end
