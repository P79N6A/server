class R

  # constructors
  def R uri = nil
    uri ? (R.new uri) : self
  end
  def R.[] uri; R.new uri end

  # equality / comparison
  def ==  u; to_s == u.to_s end
  def <=> c; to_s <=> c.to_s end

  # append
  def + u; R uri + u.to_s end
  alias_method :a, :+

  # string parts with nulls as empty-string
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

  # container traverses
  def justPath; hierPart.R.setEnv(@r) end
  def descend; uri.t.R end
  def child u; descend + u.to_s end
  def dirname; schemePart + hostPart + (File.dirname pathPart) end
  def dir; dirname.R end
  def parentURI; R schemePart + hostPart + Pathname.new(hierPart).parent.to_s end
  def children; node.c.map &:R end
  alias_method :c, :children
  def hierarchy; hierPart.match(/^[.\/]+$/) ? [self] : [self].concat(parentURI.hierarchy) end
  def cascade; stripSlash.hierarchy end
  def triplrContainer
    dir = uri.t
    yield dir, Type, R[Container]
    yield dir, SIOC+'has_container', dir.R.dir unless path=='/'
    mt = mtime
    yield dir, Mtime, mt.to_i
    yield dir, Date, mt.iso8601
    contained = c
    yield dir, Size, contained.size
    contained.map{|c|
      if c.directory?
        child = c.descend # trailing-slash directory-URI convention
        yield dir, LDP+'contains', child
      else # doc
        yield dir, LDP+'contains', c.stripDoc # link to generic resource
      end
    } unless contained.size > 42
  end

  # POSIX-path mapping
  VHosts = 'domain'
  def pathPOSIX; FSbase + '/' + pathPOSIXrel end
  def node; Pathname.new pathPOSIX end
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
  def inside; node.expand_path.to_s.index(FSbase) == 0 end # jail path
  def sh; pathPOSIX.utf8.sh end # shell-escape path
  def glob; (Pathname.glob pathPOSIX).map &:R end
  def realpath # follow all the links
    node.realpath
  rescue Exception => x # warn on errors.. dangling-symlinks, permission failure
    puts x
  end
  def realURI; realpath.do{|p|p.R} end
  def exist?; node.exist? end
  alias_method :e, :exist?
  def directory?; node.directory? end
  def file?; node.file? end
  alias_method :f, :file?
  def symlink?; node.symlink? end
  def mtime; node.stat.mtime if e end
  alias_method :m, :mtime
  def size; node.size end

  # balanced-containers. hash as string-arg
  def R.dive s
    s[0..2] + '/' + s[3..-1]
  end
  
  # squashed names
  def expand;   uri.expand.R end
  def shorten;  uri.shorten.R end

  # document URIs
  def docroot
    @docroot ||= stripFrag.stripDoc.stripSlash
  end
  def stripFrag; R uri.split(/#/)[0] end
  def stripDoc;  R[uri.sub /\.(e|ht|html|json|md|n3|ttl|txt)$/,''].setEnv(@r) end
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
  def n3; docroot.a '.n3' end
  def ttl; docroot.a '.ttl' end
  def jsonDoc; docroot.a '.e' end

end

class String

  def h; Digest::SHA1.hexdigest self end

  def tail; self[1..-1] end

  def t; match(/\/$/) ? self : self+'/' end

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
     gsub('|','/')) # no prefix found, squash to basename
  end

  def shorten
    R::Prefix.map{|p,f|
      return p + ':' + self[f.size..-1]  if (index f) == 0
    }
    gsub('/','|')
  end

  def sh; Shellwords.escape self end

end

module Th
  def host; self['SERVER_NAME'] end
  def scheme; self['rack.url_scheme'] end
end

class Pathname

  def R
    R.unPOSIX to_s.utf8
  end

end
