class E

  # E -> [node]
  def subtree *a
    u.take *a
  end

  fn 'set/subtree',->d,r,m{
    c =(r['c'].do{|c|c.to_i + 1} || 3).max(100) # one extra for start of next-page
    o = r['d'] =~ /^a/ ? :asc : :desc           # direction
    ('/'.E.take c, o, d.uri).do{|s|             # take subtree
      desc, asc = o == :desc ?                  # orient pagination hints
      [s.pop, s[0]] : [s[0], s.pop]
      m['prev'] = {'uri' => 'prev', 'url' => desc.url,'d' => 'desc'}
      m['next'] = {'uri' => 'next', 'url' => asc.url, 'd' => 'asc'}
      s }}

  # subtree traverse calculated-at-request-time root path
  fn 'set/index',->d,r,m{
    (r['p'].expand.E.rangePO d,
     (r['c']&&
      r['c'].to_i.max(808)+1 || 22),
     (r['d']&&
      r['d'].match(/^(a|de)sc$/) &&
      r['d'].to_sym ||
      :desc),
     ('/'+r['b']).gsub(/\/+/,'/')).do{|s|
      a,b=s[0],s.size>1 && s.pop
      desc,asc=r['d']&&
               r['d']=='asc'&&
               [a,b]||[b,a] 
      m['prev']={'uri' => 'prev','url' => d.url,'d' => 'desc','b' => desc.uri} if desc
      m['next']={'uri' => 'next','url' => d.url,'d' => 'asc','b' => asc.uri} if asc
      s }}

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
