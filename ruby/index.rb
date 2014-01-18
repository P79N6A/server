watch __FILE__
class E

  # POSIX-fs based index of triples
  # 

  # index a triple
  def index p,o
    p = p.E
    indexEdit p, (o.class == E ? o : p.literal(o)), nil
  end

  # index a triple - no type-normalization
  def indexEdit p,o,a
    return if @noIndex
#    puts "index #{p} #{o} #{a}"
    p.pIndex.noIndex[o,self,a]
  end
  def noIndex
    @noIndex = 1
    self
  end

  # reachable graph along named predicate
  def walk p, g={}, v={}
#    puts "walk #{uri}"
    graph g       # cumulative graph
    v[uri] = true # visited mark

    rel = g[uri].do{|s|s[p]} ||[]
    rev = (p.E.po self) ||[]

    rel.concat(rev).map{|r|
      v[r.uri] || (r.E.walk p,g,v)}

    g
  end

  fn 'set/subtree',->d,r,m{
    c =(r['c'].do{|c|c.to_i + 1} || 8).max(100) # one extra for start of next-page
    o = r['d'] =~ /^a/ ? :asc : :desc           # direction
    (d.pathSegment.take c, o, r['offset'].do{|o|o.E}).do{|s|        # take subtree
      first, last = s[0], s.size > 1 && s.pop
      desc, asc = o == :asc ? [first,last] : [last,first]
      u = m['#']
      u[Type] = E[HTTP+'Response']
      u[Prev] = {'uri' => d.uri + '?set=subtree&d=desc&offset=' + (URI.escape desc.uri)} if desc
      u[Next] = {'uri' => d.uri + '?set=subtree&d=asc&offset=' + (URI.escape asc.uri)} if asc
      s }}

  # predicate index
  def pIndex
    shorten.prependURI '/index/'
  end

  # predicate+object index
  def poIndex o
    pIndex.concatURI o
  end
 
  # predicate+object index lookup
  def po o
    pIndex[o.class == E ? o : literal(o)]
  end

  # range query - predicate
  def rangeP size=8, dir=:desc, offset=nil, object=nil
    pIndex.subtree(size,dir,offset).map &:ro
  end

  # range query - predicate+object
  def rangePO n=8,d=:desc,s=nil,o
    poIndex(o).subtree(n,d,s).map &:ro
  end

  # E -> [node]
  def subtree *a
    u.take *a
  end

  # E -> [E]
  def take *a
    no.take(*a).map &:E
  end

  def randomLeaf
    c.empty? && self || c.r.randomLeaf
  end

  def E.graphProperties g
    g.values.select{|v|v.respond_to? :keys}.map(&:keys).flatten.uniq
  end

  fn 'set/randomLeaf',->d,e,m{[d.randomLeaf]}
  fn 'req/randomLeaf',->e,r{[302, {Location: e.randomLeaf.uri},[]]}

end


class Pathname

  # fs sorted depth-first subtree
  def take count=1000, direction=:desc, offset=nil
    offset = offset.d if offset

    ok = false    # in-range mark
    set=[]
    v,m={asc:      [:id,:>=],
        desc: [:reverse,:<=]}[direction]

    visit=->nodes{
      nodes.sort_by(&:to_s).send(v).each{|n|
        ns = n.to_s
        return if 0 >= count

        (ok || # already in-range
         !offset || # no offset required
         (sz = [ns,offset].map(&:size).min
          ns[0..sz-1].send(m,offset[0..sz-1]))) &&
        (if !(c = n.c).empty? # has children?
           visit.(c)          # visit children
         else
           count = count - 1 # decrement nodes-left count
           set.push n        # add node to result-set
           ok = true         # mark iterator as within range
        end )}}

    visit.(c)
    set
  end

end
