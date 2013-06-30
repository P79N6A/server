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
  fn 'req/randomLeaf',->e,r{[302, {Location: e.randomLeaf.uri},[]]}

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

  # Graph -> [Predicate]
  def E.graphProperties g
    g.values.select{|v|v.respond_to? :keys}.map(&:keys).flatten.uniq
  end

  fn 'filter/p',->e,m{
    a=Hash[*e['p'].split(/,/).map(&:expand).map{|p|[p,true]}.flatten]
    m.values.map{|r|
      r.delete_if{|p,o|!a[p]}
    }}

  fn 'filter/frag',->e,m{
    f = m['frag']['res']
    m.keys.map{|u|
      m.delete u unless f.member? u
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
