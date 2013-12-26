#watch __FILE__
class E
 
  fn 'filter.p',->e,m,_{
    a=Hash[*e['p'].split(/,/).map(&:expand).map{|p|[p,true]}.flatten]
    m.values.map{|r|
      r.delete_if{|p,o|!a[p]}}}

  fn 'filter.set',->e,m,r{
    # result-sets have RDFs set-members
    # filter=set narrows graph to these, gone will be data on the docs containing the data or other fragment identifiers which didn't match keyword-search terms if indexing granularity is smaller than doc-level
    uri = r.env['REQUEST_URI']
    f = [uri] # container
    m[uri].do{|c|c[RDFs+'member'].do{|m| f.concat m.map &:uri }} # members
    m.keys.map{|u| m.delete u unless f.member? u}} # trim

  fn 'filter.basic',->o,m,_{
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

  fn 'filter.map',->o,m,_{
    o.except('filter','graph','view').map{|p,n|
     p=p.expand
     n=n.expand
      p!=n &&
      m.values.map{|r|
        r[p].do{|o|
          r[n]=o
          r.delete p }}}}

  fn 'view/map',->d,e{
    [H.js('/js/normal'),(H.once e,:mu,(H.js '/js/mu')),
'<style>.b {display:inline-block;font-weight:bold;padding-right:.8em;text-align:right;min-width:12em}
        .exerpt {display:inline-block;max-height:1em;overflow:hidden;max-width:44em;font-size: .9em} </style>',
     {_: :form, c:
      [d.values.map(&:keys).flatten.uniq.-(['uri']).do{|ps|
        ps.map{|p|
           [{class: :b, c: p},{_: :select, name: p, c: 
            (ps + [Date,Creator,Content,Title]).map{|q|
              {_: :option, c: q}.
                  update(p==q ? {selected: :selected}:{})}},
              {class: :exerpt, c: d.values.map{|r|r[p]}.flatten.uniq.html},
              '<br>']}},
       {_: :input, type: :hidden, name: :view, value: :tab},
       {_: :input, type: :hidden, name: :filter, value: :map},
       {_: :input, type: :submit}
       ]}]}
  
  def self.filter o,m,r
    o['filter'].do{|f| # user-supplied
      f.split(/,/).map{|f| # comma-seperated filters
        F['filter.'+f].do{|f|f[o,m,r]}}} # if they exist

    Fn'filter.basic',o,m,r if o.has_any_key ['reverse','sort','max','min','match']
    m
  end

  def E.graphProperties g
    g.values.select{|v|v.respond_to? :keys}.map(&:keys).flatten.uniq
  end

end
