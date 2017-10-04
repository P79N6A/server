# coding: utf-8
# external dependencies
%w{cgi csv date digest/sha2 dimensions fileutils json linkeddata mail open-uri pathname rack rdf redcarpet shellwords}.map{|r|require r}
# this library
%w{MIME HTML HTTP}.map{|r|require_relative r}
# minimal and shrinking additions to stdlib classes
class Array
  def intersperse i; inject([]){|a,b|a << b << i}[0..-2] end
  def justArray; self end
end
class FalseClass
  def do; false end
end
class Hash
  def R; R.new self["uri"] end
  def uri; self["uri"] end
  def types; self[R::Type].justArray.select{|t|t.respond_to? :uri}.map &:uri end
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
# everything is a Resource, or an R to save typing
class RDF::URI
  def R; R.new to_s end
end
class RDF::Node
  def R; R.new to_s end
end
class Pathname
  def R; R.fromPOSIX to_s.utf8 end
end
class R < RDF::URI

  def R; self end
  def R.[] uri; R.new uri end

  def + u; R[uri + u.to_s].setEnv @r end
  def <=> c; to_s <=> c.to_s end
  def ==  u; to_s == u.to_s end

end
