
# dependencies
%w{cgi csv date digest/sha2 dimensions fileutils icalendar json linkeddata mail nokogiri open-uri pathname rack rdf redcarpet shellwords}.map{|r|require r}

# this library
%w{URI HTML HTTP JSON MIME POSIX RDF Cache Calendar Chat Container Feed Image Mail Post Proxy Search Style Text Time}.map{|i|require_relative i}

# class name shorthand
R = WebResource

# extensions to stdlib classes
class Array
  # already an array
  def justArray; self end
  def intersperse i; inject([]){|a,b|a << b << i}[0..-2] end
end

class Object
  # objA -> [objA]
  def justArray; [self] end
  # arg exists, run block
  def do; yield self end
  # cast to Time object
  def to_time; [Time, DateTime].member?(self.class) ? self : Time.parse(self) end
end

class FalseClass
  # return false. no yield, no block execution
  def do; self end
end

class NilClass
  # empty array
  def justArray; [] end
  # null argument: no yield, no block execution
  def do; self end
end
