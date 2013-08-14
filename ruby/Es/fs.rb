class E

  # POSIX-filesystem index for triples
  # 

  # index a triple 
  def index p,o
    # normalize predicate typeclass (accept URI string or resources) 
    indexEdit E(p),
    # literal -> URI conversion
      (o.class == E ? o : E(p).literal(o)),
       nil
  end

  # index a triple - no input-cleanup
  def indexEdit p,o,a
    return if @noIndex
    p.pIndex.noIndex[o,self,a]
  end
  def noIndex
    @noIndex = 1
    self
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
     ('/'+r['b']).gsub(/\/+/,'/'),
     # object
     (d if f == :rangePO)
     ).do{|s|
      # pagination pointers
      a,b = s[0], s.size > 1 && s.pop
      desc,asc = r['d'] && r['d']=='asc' && [a,b]||[b,a]
      # insert pointers in response-graph
      m['prev']={'uri' => 'prev','url' => d.url,'d' => 'desc','b' => desc.uri} if desc
      m['next']={'uri' => 'next','url' => d.url,'d' => 'asc', 'b' => asc.uri}  if asc
      s }}
  F['set/indexPO']=F['set/index']
  fn 'set/indexP',->d,r,m{Fn 'set/index',d,r,m,:rangeP}

  # predicate index
  def pIndex
    '/index'.E.s self
  end

  # predicate-object index
  def poIndex o
    pIndex.s o
  end
 
  # predicate-object index lookup
  def po o
    pIndex[o.class == E ? o : literal(o)]
  end

  # range query - predicate
  def rangeP n=8,d=:desc,s=nil,o=nil
    puts "rangeP #{uri} count #{n} dir #{d} cursor #{s}"
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

end


class Pathname

  def take s=1000,v=:desc,o=nil # count, direction, offset
    i = to_s.size # comparison offset-index
    o=o.gsub(/\/+/,'/') if o # offset
    l = false     # in-range indicator
    r=[]          # result set
    v,m={asc: [:id,:>=], desc: [:reverse,:<=]}[v] # asc/desc operator lookup
    a=->n{ s = s - 1; r.push n }                  # add to result-set, decrement count
    g=->b{ b.sort_by(&:to_s).send(v).each{|n|     # each child-element
        return if 0 >= s                          # stop if count reaches 0
        (l || !o || n.to_s[i..i+o.size-1].send(m,o[0..(n.to_s.size - i - 1)])) && # in range?
        (if !(c=n.c).empty?  # has children?
           g.(c)             # include children
         else
           a.(n)             # add resource
           l = true unless l # iterator in range
        end)}}
    g.(c) # start 
    r     # result set
  end

end
