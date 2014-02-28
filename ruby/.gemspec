Gem::Specification.new do |s|
  s.name = "infod"
  s.version = "0.0.3.5"
  s.description = "a HTTP server"
  s.summary = "webize your filesystem"
  s.executables = %w(infod)
  s.files = ['bin/infod','infod.rb'] + Dir.glob('infod/*.rb')
  s.homepage = "http://whats-your.name/www/"
  s.licenses = ["Unlicense"]
  s.require_path = "."
  %w{linkeddata mail nokogiri rack thin}.map{|d|
   s.add_runtime_dependency d, '~> 0' }
  s.authors = ['<carmen@whats-your.name>']
  s.email = "_@whats-your.name"
end
