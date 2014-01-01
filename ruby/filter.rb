#watch __FILE__
class E
 
  fn 'filter.set',->e,m,r{
    # filter to RDFs set-members
    # gone will be:
    # data about docs containing the data
    # other fragments in a doc not matching keyword-search terms when indexed per-fragment
    f = m['#'].do{|c| c[RDFs+'member'].do{|m| m.map &:uri }} || [] # members
    m.keys.map{|u| m.delete u unless f.member? u}} # trim

  fn 'filter.map',->o,m,_{
    o.map{|p,n|
     p = p.expand
     n = n.expand
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
    m
  end

  def E.graphProperties g
    g.values.select{|v|v.respond_to? :keys}.map(&:keys).flatten.uniq
  end

end
