Gem::Specification.new do |s|
  s.name = "infod"
  s.version = "0.0.1"
  s.authors = ["Carmen D Rocco"]
  s.date = "2013-09-01"
  s.description = "a webserver"
  s.email = "_@whats-your.name"
  s.files = ['infodaemon.rb'] + Dir.glob('infodaemon/**/*.rb')
  s.homepage = "http://whats-your.name/www/"
  s.licenses = ["Unlicense"]
  s.require_path = "."
  s.summary = "httpd for linked-data"
  s.add_runtime_dependency(%q<thin>, [">= 1.5"])
end
