# coding: utf-8
%w{cgi csv date digest/sha2 dimensions fileutils json linkeddata mail nokogiri open-uri pathname rack rdf redcarpet shellwords}.map{|r|require r}
class R < RDF::URI
  def R; self end
  def R.[] uri; R.new uri end
end
%w{MIME HTML HTTP}.map{|r|require_relative r}
class Array
  #       [a] -> [a]
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
  #       nil -> []
  def justArray; [] end
  def do; self end
end
class Object
  #         a -> [a]
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
=begin
  "Everything is a resource". call #R to return an abstract resource of class R
  to call resource-methods from a shell environment add R to PATH:

 ~ R https://readwrite.com feeds
https://readwrite.com/feed/
https://readwrite.com/comments/feed/

 ~/web R https://readwrite.com/feed/ getFeed
/2017/11/02/16/56:05.readwrite.com.2017.11.02.iphone.x.coming.ar.apps.booming
/2017/11/02/12/34:44.readwrite.com.2017.11.02.farm.fridge.iiot.love.story
/2017/10/25/17/54:01.readwrite.com.2017.10.25.consider.expansion.shenzhen

=end
