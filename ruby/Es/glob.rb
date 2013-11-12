class E

  # glob :: pattern -> [E]
  def glob p=""
    (Pathname.glob d + p).map &:E
  end

  fn 'set/glob',->d,e=nil,_=nil{
    [d,d.pathSegment].compact.map(&:glob).flatten[0..3e3]}

  fn 'req/randomFile',->e,r{
    g = F['set/glob'][e]
    !g.empty? ? [302, {Location: g.random.uri}, []] : [404]}

  def docs
    doc = self if e # directly-referenced doc
    docs = docBase.glob ".{e,html,n3,nt,owl,rdf,ttl}" # basename-sharing docs
    dir = (d? && uri[-1]=='/' && uri.size>1) ? c : [] # trailing slash descends
    [doc,docs,dir].flatten.compact
  end

end
