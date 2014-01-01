#watch __FILE__
class E
 
  fn 'filter.set',->e,m,r{
    # filter to RDFs set-members
    # gone will be:
    # data about docs containing the data
    # other fragments in a doc not matching keyword-search terms when indexed per-fragment
    f = m['#'].do{|c| c[RDFs+'member'].do{|m| m.map &:uri }} || [] # members
    m.keys.map{|u| m.delete u unless f.member? u}} # trim

  def self.filter o,m,r
    o['filter'].do{|f| # user-supplied
      f.split(/,/).map{|f| # comma-seperated filters
        F['filter.'+f].do{|f|f[o,m,r]}}} # if they exist
    m
  end

end
