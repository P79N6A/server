class E
=begin
  customization, not loaded by default

  echo 'require "element/Th/robots"' >> http://site/local.rb 

=end

 fn '/robots.txt/GET',->e,r{
 [200,{'Content-Type'=>'text/plain'},["
User-agent: *
Disallow: /*?*
"]]}

end
