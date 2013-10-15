class E

  # POSIX-fs backed index of triples
  # 

  # index a triple 
  def index p,o
    # normalize predicate types (accept URI string or resources) 
    indexEdit E(p),
    # literal -> URI conversion
      (o.class == E ? o : E(p).literal(o)),
       nil
  end

  # index a triple - no input-casting
  def indexEdit p,o,a
    return if @noIndex
    p.pIndex.noIndex[o,self,a]
  end
  def noIndex
    @noIndex = 1
    self
  end

  # accumulate a graph recursively along set-membership arc
  def walk p,m={}
    graph m # accumulative graph
    o = []  # resources to visit 
    o.concat m[uri][p]     # outgoing arc targets
    o.concat (E p).po self # incoming arc sources
    o.map{|r|              # walk
      r.E.walk p,m unless m[r.uri]}
    m
  end

  # subtree traverse
  fn 'set/subtree',->d,r,m{
    c =(r['c'].do{|c|c.to_i + 1} || 3).max(100) # one extra for start of next-page
    o = r['d'] =~ /^a/ ? :asc : :desc           # direction
    ('/'.E.take c, o, d.uri).do{|s|             # take subtree
      desc, asc = o == :desc ?                  # orient pagination hints
      [s.pop, s[0]] : [s[0], s.pop]
      m['prev'] = {'uri' => 'prev', 'url' => desc.url,'d' => 'desc'}
      m['next'] = {'uri' => 'next', 'url' => asc.url, 'd' => 'asc'}
      s }}

  # subtree traverse index on p+o cursor
  fn 'set/index',->d,r,m,f=:rangePO{
    (# predicate
     (f == :rangeP ? d : r['p']).expand.E.
     # query
     send f,
     # count
     (r['c']&&
      r['c'].to_i.max(808)+1 || 22),
     # direction
     (r['d']&&
      r['d'].match(/^(a|de)sc$/) &&
      r['d'].to_sym ||
      :desc),
     # offset
     r['offset'],
     # object
     (d if f == :rangePO)
     ).do{|s|
      # pagination pointers
      a,b = s[0], s.size > 1 && s.pop
      desc,asc = r['d'] && r['d']=='asc' && [a,b]||[b,a]
      # insert pointers in response-graph
      m['prev']={'uri' => 'prev','url' => d.url,'d' => 'desc','offset' => desc.uri} if desc
      m['next']={'uri' => 'next','url' => d.url,'d' => 'asc', 'offset' => asc.uri}  if asc
      s }}
  F['set/indexPO']=F['set/index']
  fn 'set/indexP',->d,r,m{Fn 'set/index',d,r,m,:rangeP}

  # predicate index
  def pIndex
    '/index'.E.concatURI self
  end

  # predicate-object index
  def poIndex o
    pIndex.concatURI o
  end
 
  # predicate-object index lookup
  def po o
    pIndex[o.class == E ? o : literal(o)]
  end

  # range query - predicate
  def rangeP n=8,d=:desc,s=nil,o=nil
#    puts "rangeP #{uri} count #{n} dir #{d} cursor #{s}"
    pIndex.subtree(n,d,s).map &:ro
  end

  # range query - predicate-object
  def rangePO n=8,d=:desc,s=nil,o
#    puts "rangePO #{uri} #{o} count #{n} dir #{d} cursor #{s}"
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

  # random leaf
  def randomLeaf
    c.empty? && self || c.r.randomLeaf
  end
  fn 'set/randomLeaf',->d,e,m{[d.randomLeaf]}
  fn 'req/randomLeaf',->e,r{[302, {Location: e.randomLeaf.uri},[]]}

end


class Pathname

  # take N els from fs tree in sorted, depth-first order
  def take count=1000, direction=:desc, offset=nil

    # construct offset-path
    offset = to_s + offset.gsub(/\/+/,'/').E.path if offset

    # in-range indicator
    ok = false

    # result set
    set=[]

    # asc/desc operators
    v,m={asc:      [:id,:>=],
        desc: [:reverse,:<=]}[direction]

    # visitation function
    visit=->nodes{
      
      # sort nodes in asc or desc order
      nodes.sort_by(&:to_s).send(v).each{|n|
        ns = n.to_s
        # have we got enough nodes?
        return if 0 >= count

        # continue if
        (# already in-range
         ok ||
         # no offset specified
         !offset ||
         # offset satisfies in-range operator
         (sz = [ns,offset].map(&:size).min
          ns[0..sz-1].send(m,offset[0..sz-1]))) && (
         if !(c = n.c).empty? # has children?
           visit.(c)          # visit children
         else
           count = count - 1 # decrement wanted-nodes count
           set.push n        # add node to result-set
           ok = true         # iterator is now within range
        end )}}

    visit.(c) # start 

    # result set
    set
  end

end
