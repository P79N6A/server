Gem::Specification.new do |s|
  s.name = "infod"
  s.version = "0.0.3.4"
  s.description = "linked-data oriented webserver"
  s.summary = s.description
  s.executables = %w(R ww)
  s.files = Dir.glob('rrww/*')
  s.licenses = ["Unlicense"]
  s.require_path = "."
  %w{rack thin nokogiri linkeddata}.map{|d| s.add_dependency d }
  s.authors = ['<carmen@whats-your.name>']
  s.email = "_@whats-your.name"
end
