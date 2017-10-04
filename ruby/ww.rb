# coding: utf-8
# external dependencies
%w{cgi csv date digest/sha2 dimensions fileutils json linkeddata mail open-uri pathname rack rdf redcarpet shellwords}.map{|r|require r}
# this library
class R < RDF::URI
  def R; self end
  def R.[] uri; R.new uri end
end
%w{MIME HTML HTTP}.map{|r|require_relative r}
# extraclass methods for type-normalizing and conditional code
# justArray: [a,r,r,a,y] for [a,r,r,a,y], [object] for object, [] for nil
# R: Resource from anything with URI attribute
# do: if arg exists yield it to a one-arg code-block
class Array
  def justArray; self end
end
class FalseClass
  def do; false end
end
class Hash
  def R; R.new self["uri"] end
  def uri; self["uri"] end
end
class NilClass
  def do; nil end
  def justArray; [] end
end
class Object
  def id; self end
  def do; yield self end
  def justArray; [self] end
  def to_time
    [Time, DateTime].member?(self.class) ? self : Time.parse(self)
  end
end
class RDF::URI
  def R; R.new to_s end
end
class RDF::Node
  def R; R.new to_s end
end
class Pathname
  def R; R.fromPOSIX to_s.utf8 end
end
