Gem::Specification.new do |s|
  s.name = "infod"
  s.version = "0.0.3.4"
  s.description = "a web-server"
  s.summary = s.description
  s.executables = %w(R ww)
  s.files = Dir.glob('ww/*') # ln -s . ww in ruby (or use desired name)
  s.licenses = ["Unlicense"]
  s.require_path = "."
  %w{rack thin nokogiri linkeddata}.map{|d| s.add_dependency d }
  s.authors = ['<carmen@whats-your.name>']
  s.email = "carmen@whats-your.name"
end
