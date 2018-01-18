# coding: utf-8
%w{cgi csv date digest/sha2 dimensions fileutils icalendar json linkeddata mail nokogiri open-uri pathname rack rdf redcarpet shellwords}.map{|r|require r}
%w{URI MIME HTTP HTML POSIX Feed JSON Text Mail Table Tree Calendar Chat Icons Image}.map{|i|require_relative i}
R = WebResource
class Array
  def justArray; self end
  def intersperse i; inject([]){|a,b|a << b << i}[0..-2] end
end
class FalseClass
  def do; self end
end
class NilClass
  def justArray; [] end
  def do; self end
end
class Object
  def justArray; [self] end
  def id; self end
  def do; yield self end
  def to_time; [Time, DateTime].member?(self.class) ? self : Time.parse(self) end
end
