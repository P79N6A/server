class E

  # snapshot identifier
  def snap
    a=Time.now
    docBaseURI.
      as(Fn'cal/day').
      as(a.strftime('%H%M.%S'+a.usec.to_s)).
      a('.'+((URI uri).path.E.ext).do{|e|e.empty? ? 'html' : e})
  end

  # save resource to a local snapshot
  def archive
    snap.w get
  end

  # versions :: q -> [E]
  def versions r={}
    c = (r['c']||18).to_i.max(188) +1 # count
    d = (r['d']||:desc).to_sym # direction
    i = r['i'] # start
    docBaseURI.take c,d,i # query
  end

  # a set of versions
  fn 'set/v',->d,r,m{
    (d.versions r).do{|s|
      a,b=s[0],s.size>1 && s.pop
      desc,asc=r['d'] && r['d']=='asc' &&[a,b] ||[b,a] 
      m['prev']={ 'uri' => 'prev','url' => d.url,'d' => 'desc',
        'i' => desc.uri.tail.do{|p|p[d.docBaseURI.uri.size..-1]}} if desc
      m['next']={ 'uri' => 'next','url' => d.url,'d' => 'asc',
        'i' => asc.uri.tail.do{|p|p[d.docBaseURI.uri.size..-1]}} if asc
      s }}

end
