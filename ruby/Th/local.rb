class E
=begin
 this code is not loaded by default

 server looks in hostname-root paths for *.rb files, reporting found code:
 site config http://data.whats-your.name/data.rb 

=end
  
  # disallow custom-query crawling on all sites
  fn '/robots.txt/GET',->e,r{
    [200,{'Content-Type'=>'text/plain'},["User-agent: *\nDisallow: /*?*\n"]]}
  
  # schema search forward from site root
  fn 'http://data.whats-your.name/GET',->e,r{
    [302,{'Location'=>'/schema'},[]]}  
  
  # webize PS(1)
  fn '/ps/GET',->e,r{
    [200,{'Content-Type'=>'text/plain'},[`ps aux`]]}

end
