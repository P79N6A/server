class E

  # narrow to specified properties
  fn 'filter/p',->e,m,_{
    a=Hash[*e['p'].split(/,/).map(&:expand).map{|p|[p,true]}.flatten]
    m.values.map{|r|
      r.delete_if{|p,o|!a[p]}}}

  fn 'filter/frag',->e,m,r{
    f = [r.uri].concat m['frag']['res']
    m.keys.map{|u|
      m.delete u unless f.member? u}}

  fn 'filter/basic',->o,m,_{
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
  
  def self.filter o,m,r
    o['filter'].do{|f|f.split(/,/).map{|f|Fn 'filter/'+f,o,m,r}}
    Fn'filter/basic',o,m,r if o.has_any_key ['reverse','sort','max','min','match']
    m
  end

  def E.graphProperties g
    g.values.select{|v|v.respond_to? :keys}.map(&:keys).flatten.uniq
  end

end
