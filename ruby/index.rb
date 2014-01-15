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

  # subtree traverse
  fn 'set/subtree',->d,r,m{
    c =(r['c'].do{|c|c.to_i + 1} || 3).max(100) # one extra for start of next-page
    o = r['d'] =~ /^a/ ? :asc : :desc           # direction

    ('/'.E.take c, o, d.uri).do{|s|             # take subtree
      desc, asc = o == :desc ?                  # orient pagination hints
      [s.pop, s[0]] : [s[0], s.pop]
      u = m['#']
      u[Type] = E[HTTP+'Response']
      u[Prev] = {'uri' => desc.url + {'d' => 'desc'}.qs} if desc
      u[Next] = {'uri' => asc.url  + {'d' => 'asc'}.qs} if asc
      s }}

  # subtree traverse index on p+o cursor
  fn 'set/index',->d,r,m{
    top = r['p'].expand.E
    count = r['c'] &&
            r['c'].to_i.max(1000) || 8
    dir = r['d'] && r['d'].match(/^(a|de)sc$/) &&
          r['d'].to_sym || :desc

    (top.rangePO count+1, dir, r['offset'], r['o']).do{|s|
      # orient pagination pointers
      ascending = r['d'].do{|d| d == 'asc' }
      first, last = s[0], s.size > 1 && s.pop
      desc, asc = ascending && [first,last] || [last,first]
      # response description
      u = m['#']
      u[RDFs+'member'] = s
      u[Prev] = {'uri' => '/index/' + r['p'] + '/' + CGI.escape(r['o']) + {'offset' => desc.uri, 'c' => count}.qs } if desc
      u[Next] = {'uri' => '/index/' + r['p'] + '/' + CGI.escape(r['o']) + {'offset' => asc.uri, 'c' => count}.qs } if asc

      s.map(&:docs).flatten.uniq }}

  fn '/index/GET',->e,r{
    a = e.pathSegment.uri[7..-1].split '/',2
    r.q['set'] = 'index'
    r.q['p'] = a[0]
    r.q['o'] = CGI.unescape a[1]
    e.response}

  # predicate index
  def pIndex
    shorten.prependURI '/index/'
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
  def rangeP size=8, dir=:desc, offset=nil, object=nil
    pIndex.subtree(size,dir,offset).map &:ro
  end

  # range query - predicate-object
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

  # take N els from fs tree in sorted, depth-first order
  def take count=1000, direction=:desc, offset=nil

    # construct offset-path
    offset = (to_s + offset).gsub(/\/+/,'/').E.path if offset

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
