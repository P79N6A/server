# coding: utf-8
%w{cgi csv date digest/sha1 dimensions fileutils json linkeddata mail nokogiri open-uri pathname rack rdf redcarpet shellwords}.map{|r|require r}
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
class RDF::URI
  def R; R.new to_s end
end
class Pathname
  def R; R.unPOSIX to_s.utf8 end
end
class R < RDF::URI
  # URI constants
  W3 = 'http://www.w3.org/'
  OA = 'https://www.w3.org/ns/oa#'
  Purl = 'http://purl.org/'
  DC   = Purl + 'dc/terms/'
  DCe  = Purl + 'dc/elements/1.1/'
  SIOC = 'http://rdfs.org/sioc/ns#'
  Schema = 'http://schema.org/'
  Podcast = 'http://www.itunes.com/dtds/podcast-1.0.dtd#'
  Harvard  = 'http://harvard.edu/'
  Sound    = Purl + 'ontology/mo/Sound'
  Image    = DC + 'Image'
  RSS      = Purl + 'rss/1.0/'
  Date     = DC   + 'date'
  Title    = DC   + 'title'
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
  def R; self end
  def R.[] uri; R.new uri end
  def setEnv r; @r = r; self end
  def env; @r end
  alias_method :uri, :to_s
  def to_json *a; {'uri' => uri}.to_json *a end
  def ==  u; to_s == u.to_s end
  def <=> c; to_s <=> c.to_s end
  def + u; R[uri + u.to_s].setEnv @r end
  def node; Pathname.new pathPOSIX end
  def justPath; (path || '/').R.setEnv(@r) end
  def child u; R[uri + (uri[-1] == '/' ? '' : '/') + u.to_s] end
  def children; node.children.delete_if{|f|f.basename.to_s.index('.')==0}.map{|c|c.R.setEnv @r} end
  def dirname; File.dirname path end
  def dir; dirname.R end
  def glob; (Pathname.glob pathPOSIX).map{|p|p.R.setEnv @r} end
  def ext; (File.extname uri)[1..-1] || '' end
  def basename; File.basename (path||'') end
  def stripDoc; R[uri.sub /\.(e|html|json|log|md|ttl|txt)$/,''].setEnv(@r) end
  def stripSlash; uri[-1]=='/' ? uri[0..-2].R.setEnv(@r) : self end
  def tld; (host||'').split('.')[-1] || '' end
  def inside; node.expand_path.to_s.index(FSbase) == 0 end
  def sh; pathPOSIX.utf8.sh end
  def exist?; node.exist? end
  def file?; node.file? end
  def mtime; node.stat.mtime end
  def size; node.size rescue 0 end
  alias_method :e, :exist?
  alias_method :m, :mtime
  def readFile; File.open(pathPOSIX).read end
  def writeFile o; dir.mkdir; File.open(pathPOSIX,'w'){|f|f << o}; self end
  def mkdir; FileUtils.mkdir_p(pathPOSIX) unless exist?; self end
  def R.unPOSIX path; (path.match(/domain\/+(.*)/).do{|m|'//'+m[1]} || ('/'+path)).gsub(' ','%20').gsub('#','%23').R end
  def pathPOSIX; URI.unescape(host ? ('domain/'+host+(path||'')) : ((path||'').sub /^\//,'')) end
  %w{MIME HTML HTTP}.map{|r|require_relative r}
end
