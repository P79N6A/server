class E

  # glob :: pattern -> [E]
  def glob p=""
    (Pathname.glob d + p).map &:E
  end

  fn 'set/glob',->d,e=nil,_=nil{
    p = [d,d.pathSegment].compact.map(&:glob).flatten[0..4e2].compact.partition &:inside
    p[0] }

  fn 'req/randomFile',->e,r{
    g = F['set/glob'][e]
    !g.empty? ? [302, {Location: g[rand g.length].uri}, []] : [404]}

  def docs
    db = docBase
    this = self if e
    base = db if db.e
    docs = db.glob ".{e,html,n3,nt,owl,rdf,ttl}" # basename-sharing docs
    dir = (d? && uri[-1]=='/' && uri.size>1) ? c : [] # trailing slash descends
    [base,this,docs,dir].flatten.compact
  end

end
