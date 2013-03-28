%w{groonga redis}.map{|e|require 'element/Es/'+e}

class E

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

  def lev; require 'text/levenshtein'
    b = base
    (siblings-[nil]).map{|s|[s,(Text::Levenshtein.distance b,s.base)]}.select{|d|d[1]<5}.sort_by{|d|d[1]}.map &:head
    rescue LoadError
    []
  end

  def near
    (glob '*').concat lev
  end

  # resPO :: env -> [E]
  def resPO r,m
    (r[','].expand.E.rangePO self,
     (r['c']&&
      r['c'].to_i.max(808)+1 || 88),
     (r['d']&&
      r['d'].match(/^(a|de)sc$/) &&
      r['d'].to_sym ||
      :desc),
     ('/'+r['b']).gsub(/\/+/,'/')).do{|s|
      a,b=s[0],s.size>1 && s.pop
      desc,asc=r['d']&&
               r['d']=='asc'&&
               [a,b]||[b,a] 
      m['prev']={'uri' => 'prev','url' => url,'d' => 'desc','b' => desc.uri} if desc
      m['next']={'uri' => 'next','url' => url,'d' => 'asc','b' => asc.uri} if asc
      s }
  end

  # resPath :: env -> [E]
  def resPath r,m
    g = glob
    g.push self if g.empty? && (e || em.e)
    r['c'].do{|c| # tree
      ((E '/').take (c.to_i+1).max(88), # size
       r['d'].do{|d|d.to_sym}||:desc, # direction
       g[0].uri.tail).do{|s| # cursor begin
        desc,asc=r['d'].do{|d|d=~/^a/}&&
                 [s[0], s.pop] ||
                 [s.pop, s[0]]
        m['prev']={'uri' => 'prev', 'url' => desc.url,'d' => 'desc'}
        m['next']={'uri' => 'next', 'url' => asc.url, 'd' => 'asc'}
        g.concat s }} if g.size==1
    g.concat docs
  end

  # resourceSet :: env -> {uri => E}
  def resourceSet r={},m={}
   (if s=F['set/'+r['set']]
       s[self,r,m]
     elsif r[',']
       resPO r,m
     elsif path?
       resPath r,m
     else
       [self]
    end).map{|u| m[u.uri] ||= u}
    m
  end

  # recursive bidirectional monomorphic traverse
  def walk p,m={},v={}
    m.merge! memoGraph
    v[uri]=true
    ((attr p)||[]).concat(((E p).po self)||[]).map{|r|
      r.E.walk p,m,v if !v[r.uri]}
    m
  end

  fn 'filter/p',->e,m{
    a=Hash[*e['p'].split(/,/).map(&:expand).map{|p|[p,true]}.flatten]
    m.values.map{|r|
      r.delete_if{|p,o|!a[p]}
    }}

  fn 'filter/basic',->o,m{
    d=m.values
    o['match'] && (p=o['matchP'].expand
                   d=d.select{|r|r[p].do{|p|(p.class==Array ? p[0] : p).to_s.match o['match']}})
    o['min'] && (min=o['min'].to_f
                 p=o['minP'].expand
                 d=d.select{|r|r[p].do{|p|(p.class==Array ? p[0] : p).to_f >= min }})
    o['max'] && (max=o['max'].to_f
                 p=o['maxP'].expand
                 d=d.select{|r|r[p].do{|p|(p.class==Array ? p[0] : p).to_f <= max }})
    o['sort'] && (p=o['sort'].expand
                       _ = d.partition{|r|r[p]}
                       d =_[0].sort_by{|r|r[p]}.concat _[1] rescue d)
    o['sortN'] && (p=o['sortN'].expand
                       _ = d.partition{|r|r[p]}
                       d =_[0].sort_by{|r|
                     (r[p].class==Array && r[p] || [r[p]])[0].do{|d|
                       d.class==String && d.to_i || d
                     }
                   }.concat _[1])
    o.has_key?('reverse') && d.reverse!
    m.clear;d.map{|r|m[r['uri']]=r}}
  
  def self.filter o,m
    o['filter'].do{|f|f.split(/,/).map{|f|Fn 'filter/'+f,o,m}}
    Fn'filter/basic',o,m if o.has_any_key ['reverse','sort','max','min','match']
    m
  end

end

class Pathname

  Infinity = 1.0/0
  def take s=Infinity,v=:desc,o=nil# count, direction, offset
    i=to_s.size;l=false;r=[];v,m={asc: [:id,:>=], desc: [:reverse,:<=]}[v]
    a=->n{s=s-1;r.push n}
    g=->b{b.sort_by(&:to_s).send(v).each{|n|
        return if 0 >= s
        (l || !o || n.to_s[i..i+o.size-1].send(m,o[0..(n.to_s.size - i - 1)])) && # range
        (if !(c=n.c).empty?
          g.(c) # children
        else
          a.(n); l=true unless l #leaf
        end)}}
    g.(c); r
  end

end
