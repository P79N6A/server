#watch __FILE__
class R

  E404 = -> e,r,g=nil {
    r[:Response].update({'Content-Type'=>'text/html'})
    g||={} # graph
    s = g[e.uri] ||= {} # resource
    s['#query-string'] = Hash[r.q.map{|k,v|[k.to_s.hrefs,v.to_s.hrefs]}]
    s['#accept'] = r.accept
    %w{CHARSET LANGUAGE ENCODING}.map{|a|
      s['#accept-'+a.downcase] = r.accept_('_'+a)}
    r.map{|k,v| s['#'+k.to_s] = v.class==Hash ? v.dup : v}
    s['#SERVER_NAME'] = R['//'+s['#SERVER_NAME']]
    s['#uri'] = R[s['#uri']]
    s['#HTTP_REFERER'].do{|r|s['#HTTP_REFERER']=R[r]}
    s['#Response'].do{|r|r.delete 'Content-Type'}
    r.q.delete 'view'
    [404, r[:Response], [Render['text/html'][g,r]]]}

end
