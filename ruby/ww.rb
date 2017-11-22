# coding: utf-8
%w{cgi csv date digest/sha2 dimensions fileutils json linkeddata mail nokogiri open-uri pathname rack rdf redcarpet shellwords}.map{|r|require r}
# derive resource class
class R < RDF::URI
  def R; self end
  def R.[] uri; R.new uri end
end
# now the rest of the library can reopen R
%w{MIME HTML HTTP proprietary}.map{|r|require_relative r}
# #justArray returns one-element array for singleton object. obviates [] wrapping of RDF-object when construction Hash or JSON
# #R normalizes any type identifiable with a URI to our abstract resource
# #do passes object to block-arg. Kernel#yield_self in Ruby 2.5 may be faster than "yield self", TODO investigate once widely deployed
class Array
  # [a] -> [a]
  def justArray; self end
  def intersperse i; inject([]){|a,b|a << b << i}[0..-2] end
end
class FalseClass
  def do; self end
end
class Hash
  def R; R.new self["uri"] end
  def uri;     self["uri"] end
  def types; self[R::Type].justArray.select{|t|t.respond_to? :uri}.map &:uri end
end
class NilClass
  # nil -> []
  def justArray; [] end
  def do; self end
end
class Object
  # a -> [a]
  def justArray; [self] end
  def id; self end
  def do; yield self end
  def to_time; [Time, DateTime].member?(self.class) ? self : Time.parse(self) end
end
class Pathname
  def R; R.fromPOSIX to_s.utf8 end
end
class RDF::Node
  def R; R.new to_s end
end
class RDF::URI
  def R; R.new to_s end
end
