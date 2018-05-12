# deps
%w{cgi csv date digest/sha2 dimensions fileutils icalendar json linkeddata mail nokogiri open-uri pathname rack rdf redcarpet resolv-replace shellwords}.map{|r|require r}
# this library
%w{URI MIME POSIX HTML Feed JSON Text Mail Calendar Chat Icons Image HTTP}.map{|i|require_relative i}

R = WebResource # shorthand alias
# extend stdlib
class Array
  # already an array
  def justArray; self end
  def intersperse i; inject([]){|a,b|a << b << i}[0..-2] end
end
class Object
  # obj -> [obj]
  def justArray; [self] end
  # identity function
  def id; self end
  # arg exists, run block
  def do; yield self end
  # cast to Time object
  def to_time; [Time, DateTime].member?(self.class) ? self : Time.parse(self) end
end
class FalseClass
  # arg false, don't do block
  def do; self end
end
class NilClass
  # nil -> []
  def justArray; [] end
  # arg missing, don't do block
  def do; self end
end
