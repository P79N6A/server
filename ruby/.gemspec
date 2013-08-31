Gem::Specification.new do |s|
  s.name = "infod"
  s.version = "0.0.1"
  s.description = "a data/filesystem web-server"
  s.summary = s.description
  s.executables = %w(infod)
  s.files = ['bin/infod','infod.rb','config.ru'] + Dir.glob('infod/**/*.rb')
  s.homepage = "http://whats-your.name/www/"
  s.licenses = ["Unlicense"]
  s.require_path = "."
  s.add_dependency 'thin'
  s.authors = ['<carmen@whats-your.name>']
  s.email = "_@whats-your.name"
end
