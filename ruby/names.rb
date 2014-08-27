def watch f
  R::Watch[f] = File.mtime f
  puts 'dev '+f end

def R uri
  R.new uri
end

class R

  # constructors
  def R uri = nil
    uri ? (R.new uri) : self
  end
  def R.[] uri; R.new uri end

  # equality / comparison operators
  def ==  u; to_s == u.to_s end
  def <=> c; to_s <=> c.to_s end

  # append operators
  def + u; R uri + u.to_s end
  alias_method :a, :+

  # URI-parts with nil mapped to empty-string (for null-derefence-free concatenation)
  def schemePart; scheme ? scheme + ':' : '' end
  def hostPart; host ? '//' + host : '' end
  def hierPart; path || '/' end
  def queryPart; query ? '?' + query : '' end
  def fragPart; fragment ? '#' + fragment : '' end
  def pathPart; hierPart + queryPart + fragPart end
  def ext; (File.extname uri).tail || '' end
  def suffix; '.' + ext end
  def basename suffix = nil
    suffix ? (File.basename pathPart, suffix) : (File.basename pathPart) end
  def bare; basename suffix end

  # parent/child relationships within hierPart
  def descend; uri.t.R end
  def child u; descend + u.to_s end
  def dirname; schemePart + hostPart + (File.dirname pathPart) end
  def dir; dirname.R end
  def parentURI; R schemePart + hostPart + Pathname.new(hierPart).parent.to_s end
  def children; node.c.map &:R end
  alias_method :c, :children

  # recursive paths up to root
  def hierarchy; hierPart.match(/^[.\/]+$/) ? [self] : [self].concat(parentURI.hierarchy) end
  def cascade; stripSlash.hierarchy end

  # URI <> POSIX-path
  VHosts = 'domain'
  def justPath; hierPart.R end
  def pathPOSIX; FSbase + '/' + pathPOSIXrel end
  def pathPOSIXrel
    if h = host
      VHosts + '/' + h + pathPart
    else
      uri[0] == '/' ? uri.tail : uri
    end
  end
  def R.unPOSIX p, skip = R::BaseLen
    p[skip..-1].do{|p| R[ p.match(/^\/#{R::VHosts}\/+(.*)/).do{|m|'//'+m[1]} || p]}
  end
  def inside; node.expand_path.to_s.index(FSbase) == 0 end # inside site-root check
  alias_method :d, :pathPOSIX

  # strip variant-suffixes
  def stripFrag; R uri.split(/#/)[0] end
  def stripDoc;  R uri.sub Doc, '' end
  def stripSlash
    if uri[-1] == '/'
      if path == '/'
        self
      else
        uri[0..-2].R
      end
    else
      self
    end
  end
  def docroot # strip frag, suffix + slash
    stripFrag.stripDoc.stripSlash.do{|u|
      if u.path == '/'
        u + 'index' # directory-index name
      else
        u
      end}
  end

  # fs-node
  def node;    Pathname.new pathPOSIX end
  def exist?;   node.exist? end
  def directory?; node.directory? end
  def file?;    node.file? end
  def symlink?; node.symlink? end
  def readlink; node.readlink.R end
  def mtime;    node.stat.mtime if e end
  def realpath; node.realpath rescue nil end
  def sh;       d.force_encoding('UTF-8').sh end # shell-escaped POSIX path
  def size;     node.size end
  alias_method :e, :exist?
  alias_method :f, :file?
  alias_method :m, :mtime

  # balanced-prefixes container-names
  def R.dive s
    s[0..2] + '/' + s[3..-1]
  end

  # squash names to prefix:basename
  def expand;   uri.expand.R end
  def shorten;  uri.shorten.R end

end

class String

  def R
    R.new self
  end

  Expand={}
  def expand
   (Expand.has_key? self) ?
    Expand[self] :
   (Expand[self] =
     match(/([^:]+):([^\/].*)/).do{|e|
      ( R::Prefix[e[1]] || e[1]+':' )+e[2]} ||
     gsub('|','/')) # no prefix found, squash URI to basename
  end

  def shorten
    R::Prefix.map{|p,f|
      return p + ':' + self[f.size..-1]  if (index f) == 0
    }
    gsub('/','|')
  end

  def sh; Shellwords.escape self end

end
