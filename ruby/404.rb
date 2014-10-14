class R

  E404 = -> e,r,g=nil {
    g||={} # graph
    s = g[e.uri] ||= {} # resource

    s[Header+'query-string'] = Hash[r.q.map{|k,v|[k.to_s.hrefs,v.to_s.hrefs]}]
    s[Header+'accept'] = r.accept
    %w{CHARSET LANGUAGE ENCODING}.map{|a| s[Header+'accept-'+a.downcase] = r.accept_('_'+a)}
    r.map{|k,v| s[Header+k.to_s] = v}

    r.q.delete 'view'
    [404, r[:Response].update({'Content-Type'=>'text/html'}), [Render['text/html'][g,r]]]}

end
