Gem::Specification.new do |s|
  s.name = "infod"
  s.version = "0.0.3.1"
  s.description = "www-server"
  s.summary = s.description
  s.executables = %w(infod)
  s.files = ['bin/infod','infod.rb'] + Dir.glob('infod/*.rb')
  s.homepage = "http://whats-your.name/www/"
  s.licenses = ["Unlicense"]
  s.require_path = "."
  %w{rack thin nokogiri}.map{|d| s.add_dependency d }
  s.authors = ['<carmen@whats-your.name>']
  s.email = "_@whats-your.name"
end
