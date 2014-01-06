#watch __FILE__
class E
 
  fn 'filter/set',->e,m,r{
    # filter to RDFs set-members
    # gone will be:
    # data about docs containing the data
    # other fragments in a doc not matching search when indexed per-fragment
    f = m['#'].do{|c| c[RDFs+'member'].do{|m| m.map &:uri }} || [] # members
    m.keys.map{|u| m.delete u unless f.member? u}} # trim

end
