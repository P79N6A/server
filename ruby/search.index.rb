class R

  # RDF-link index

  def getIndex rev # match (? p o)
    p = path
    f = R(File.dirname(p) + '/.' + File.basename(p) + '.' + rev + '.rev').node
    f.readlines.map{|l|R l.chomp} if f.exist?
  end

  def index p, o # update index
    o = o.R
    path = o.path
    R(File.dirname(path) + '/.' + File.basename(path) + '.' + p.R.shorten + '.rev').appendFile uri
  end


  # bidirectional+recursive traverse, named predicate
  def walk pfull, pshort, g={}, v={}
    graph g       # resource-graph
    v[uri] = true # mark visited
    rel = g[uri].do{|s|s[pfull]} ||[] # forward-arcs (doc-graph)
    rev = getIndex(pshort) ||[] # inverse arcs (index)
    rel.concat(rev).map{|r|
      v[r.uri] || (r.R.walk pfull,pshort,g,v)} # walk unvisited
    g # graph
  end

  # recursive child-nodes
  def take *a
    node.take(*a).map &:R
  end

  # (?S ?P O)-match fileset. referring-resources (any predicate)
  FileSet['rev'] = -> e,req,model {(e.dir.child '.' + e.basename + '*.rev').glob}

  def triplrRevLinks
    pcs = basename('.rev').tail.split '.'
    pMini = pcs.pop
    base = pcs.join '.'
    p = pMini.expand
    o = R[dirname + base]
    triplrUriList do |s,__,_|
      yield s, Type, R[Referer]
      yield s, p, o
    end
  end

end
