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
class R < RDF::URI
  # URI constants
  W3   = 'http://www.w3.org/'
  Purl = 'http://purl.org/'
  DC   = Purl + 'dc/terms/'
  SIOC = 'http://rdfs.org/sioc/ns#'
  Schema = 'http://schema.org/'
  Podcast = 'http://www.itunes.com/dtds/podcast-1.0.dtd#'
  Sound    = Purl + 'ontology/mo/Sound'
  Image    = DC + 'Image'
  RSS      = Purl + 'rss/1.0/'
  Date     = DC   + 'date'
  Title    = DC   + 'title'
  Re       = SIOC + 'reply_of'
  Post     = SIOC + 'Post'
  To       = SIOC + 'addressed_to'
  From     = SIOC + 'has_creator'
  Creator  = SIOC + 'has_creator'
  Content  = SIOC + 'content'
  Stat     = W3   + 'ns/posix/stat#'
  CSVns    = W3   + 'ns/csv#'
  Atom     = W3   + '2005/Atom#'
  Type     = W3 + '1999/02/22-rdf-syntax-ns#type'
  Resource = W3 + '2000/01/rdf-schema#Resource'
  Label    = W3 + '2000/01/rdf-schema#label'
  Size     = Stat + 'size'
  Mtime    = Stat + 'mtime'
  Container = W3  + 'ns/ldp#Container'

  def R; self end
  def R.[] uri; R.new uri end
  def setEnv r; @r = r; self end
  def env; @r end
  alias_method :uri, :to_s
  def pathPOSIX
    (if host
     'domain/' + host + (path||'')
     else
      (path||'').sub /^\//, ''
     end).gsub('%23','#')
  end
  def R.unPOSIX path
    (path.match(/domain\/+(.*)/).do{|m|'//'+m[1]} || ('/'+path)).gsub('#','%23').R
  end
  def ==  u; to_s == u.to_s end
  def <=> c; to_s <=> c.to_s end
  def + u; R[uri + u.to_s].setEnv @r end
  def node; Pathname.new pathPOSIX end
  def justPath; (path || '/').R.setEnv(@r) end
  def child u; R[uri + (uri[-1] == '/' ? '' : '/') + u.to_s] end
  def children; node.children.delete_if{|f|f.basename.to_s.index('.')==0}.map{|c|c.R.setEnv @r} end
  def dirname; (scheme ? scheme + ':' : '') + (host ? '//' + host : '') + (File.dirname path) end
  def dir; dirname.R end
  def glob; (Pathname.glob pathPOSIX).map{|p|p.R.setEnv @r} end
  def ext; (File.extname uri)[1..-1] || '' end
  def basename; File.basename (path||'') end
  def stripDoc;  R[uri.sub /\.(e|html|json|log|md|ttl|txt)$/,''].setEnv(@r) end
  def inside; node.expand_path.to_s.index(FSbase) == 0 end # jail path to server-root
  def sh; pathPOSIX.utf8.sh end # shell-escaped local path
  def exist?; node.exist? end
  def file?; node.file? end
  def mtime; node.stat.mtime if e end
  def size; node.size rescue 0 end
  alias_method :e, :exist?
  alias_method :m, :mtime
  def readFile; File.open(pathPOSIX).read end
  def appendFile line; dir.mkdir; File.open(pathPOSIX,'a'){|f|f.write line + "\n"}; self end
  def writeFile o; dir.mkdir; File.open(pathPOSIX,'w'){|f|f << o}; self end
  def mkdir; FileUtils.mkdir_p(pathPOSIX) unless exist?; self end

  %w{MIME HTML HTTP message}.map{|r|require_relative r}

end

class RDF::URI
  def R; R.new to_s end
end

class String
  def R; R.new self end
  # text to HTML, emit URIs as RDF
  def hrefs &b
    pre,link,post = self.partition R::Href
    u = link.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;') # escape URI
    pre.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;') +    # escape pre-match
      (link.empty? && '' || '<a id="t' + rand.to_s.sha1[0..3] + '" href="' + u + '">' + # hyperlink
       (if u.match(/(gif|jpg|jpeg|jpg:large|png|webp)$/i) # image?
        yield(R::Image,u.R) if b # emit image as triple
        "<img src='#{u}'/>"           # inline image
       else
         yield(R::DC+'link',u.R) if b # emit hypertexted link
         u.sub(/^https?.../,'')       # text
        end) + '</a>') +
      (post.empty? && '' || post.hrefs(&b)) # process post-match tail
  rescue Exception => x
    puts [x.class,x.message,self[0..127]].join(" ")
    ""
  end
  def sha1; Digest::SHA1.hexdigest self end
  def to_utf8; encode('UTF-8', undef: :replace, invalid: :replace, replace: '?') end
  def utf8; force_encoding 'UTF-8' end
  def sh; Shellwords.escape self end
end

class Pathname
  def R; R.unPOSIX to_s.utf8 end
end
