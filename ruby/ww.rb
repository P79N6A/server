# coding: utf-8
# load dependencies
%w{cgi csv date digest/sha2 dimensions fileutils icalendar json linkeddata mail nokogiri open-uri pathname rack rdf redcarpet shellwords}.map{|r|require r}
class R < RDF::URI
  def R; self end
  def R.[] u; R.new u end
  def + u; R[to_s + u.to_s] end
  alias_method :uri, :to_s
  # URI constants
  module URIs
    W3 = 'http://www.w3.org/'
    OA = 'https://www.w3.org/ns/oa#'
    Purl = 'http://purl.org/'
    DC   = Purl + 'dc/terms/'
    DCe  = Purl + 'dc/elements/1.1/'
    SIOC = 'http://rdfs.org/sioc/ns#'
    Schema = 'http://schema.org/'
    Podcast = 'http://www.itunes.com/dtds/podcast-1.0.dtd#'
    Comments = 'http://wellformedweb.org/CommentAPI/commentRss'
    Sound    = Purl + 'ontology/mo/Sound'
    Image    = DC + 'Image'
    RSS      = Purl + 'rss/1.0/'
    Date     = DC   + 'date'
    Title    = DC   + 'title'
    Abstract = DC   + 'abstract'
    Post     = SIOC + 'Post'
    To       = SIOC + 'addressed_to'
    From     = SIOC + 'has_creator'
    Creator  = SIOC + 'has_creator'
    Content  = SIOC + 'content'
    Stat     = W3   + 'ns/posix/stat#'
    Atom     = W3   + '2005/Atom#'
    Type     = W3 + '1999/02/22-rdf-syntax-ns#type'
    Label    = W3 + '2000/01/rdf-schema#label'
    Size     = Stat + 'size'
    Mtime    = Stat + 'mtime'
    Container = W3  + 'ns/ldp#Container'
    Twitter = 'https://twitter.com'
    Instagram = 'https://www.instagram.com/'
  end
  # load libraries
  %w{MIME HTTP HTML JSON Feed Text POSIX Mail Calendar online}.map{|i|require_relative 'interfaces/'+i}
  # include modules
  [MIME,HTTP,HTML,POSIX,Webize,Util].map{|m|include m}
end
# TODO replace #do with #yield_self? added in ruby 2.5..
# TODO approaches to handling one vs many: remove #justArray?
class Array
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
  def justArray; [] end
  def do; self end
end
class Object
  def justArray; [self] end
  def id; self end
  def do; yield self end
  def to_time; [Time, DateTime].member?(self.class) ? self : Time.parse(self) end
end
class Pathname
  def R; R::POSIX.path to_s.utf8 end
end
class RDF::Node
  def R; R.new to_s end
end
class RDF::URI
  def R; R.new to_s end
end
