#watch __FILE__
class E

  # POSIX-fs based index of triples
  # 

  # index a triple, type-normalization wrapper
  def index p,o
    p = p.E
    index_ p, (o.class == E ? o : p.literal(o)), nil
  end

  # index a triple
  # flip position, use existing k/v store + set @noIndex to stop looping infinitely to index the index..
  def index_ p,o,a
    return if @noIndex
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

  fn 'set/depth',->d,r,m{ # depth-first
    global = !r.has_key?('local')
    p = global ? d.pathSegment : d
    loc = global ? '' : '&local'
    c = ((r['c'].do{|c|c.to_i} || 12) + 1).max(128) # an extra for next-page pointer
    o = r['d'] =~ /^a/ ? :asc : :desc            # direction
    (p.take c, o, r['offset'].do{|o|o.E}).do{|s| # take subtree
      first, last = s[0], s.size > 1 && s.pop
      desc, asc = o == :asc ? [first,last] : [last,first]
      u = m['#']
      u[Type] = E[HTTP+'Response']
      u[Prev] = {'uri' => d.uri + "?set=depth&c=#{c-1}&d=desc#{loc}&offset=" + (URI.escape desc.uri)} if desc
      u[Next] = {'uri' => d.uri + "?set=depth&c=#{c-1}&d=asc#{loc}&offset=" + (URI.escape asc.uri)} if asc
      s }}

  def pIndex
    shorten.prependURI '/index/'
  end

  def po o
    pIndex[o]
  end

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
2
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
