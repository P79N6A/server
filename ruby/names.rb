def watch f
  R::Watch[f] = File.mtime f
  puts 'dev '+f end

def R uri
  R.new uri
end

class R

  # constructor
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

  # string parts
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

  # hierPart traverses
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

  # URI <> POSIX-path
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

  # balanced-containers ( 4096 on hashed-ID)
  def R.dive s
    s[0..2] + '/' + s[3..-1]
  end
  
  # squashed names
  def expand;   uri.expand.R end
  def shorten;  uri.shorten.R end

  # document URIs
  def n3; docroot.a '.n3' end
  def ttl; docroot.a '.ttl' end
  def jsonDoc; docroot.a '.e' end

  # fragment-per-doc URIs, for "thing"-granularity storage

  # container of fragment-docs
  def fragmentDir
    doc = docroot
    doc.dir.descend + '.' + doc.basename + '/'
  end

  # fragment-docs of doc
  def fragments; fragmentDir.a('*.e').glob end

  # fragment-doc of resource
  def fragmentPath
    f = fragment
    f = '_' if !f
    f = '__' if f.empty?
    fragmentDir + f
  end

  # filesystem name-lookups
  def glob; (Pathname.glob pathPOSIX).map &:R end
  def realpath # follow all the links
    node.realpath
  rescue Exception => x # warn on errors.. dangling-symlinks, permission failure
    puts x
  end
  def realURI; realpath.do{|p|p.R} end
  def exist?;   node.exist? end
  alias_method :e, :exist?
  def directory?; node.directory? end
  def file?;    node.file? end
  alias_method :f, :file?
  def symlink?; node.symlink? end
  def mtime;    node.stat.mtime if e end
  alias_method :m, :mtime
  def size;     node.size end

  # filesystem name-storage
  def triplrContainer
    dir = uri.t # trailing-slash

    yield dir, Type, R[Directory]
    yield dir, SIOC+'has_container', parentURI unless path=='/'
    mt = mtime
    yield dir, Mtime, mt.to_i
    yield dir, Date, mt.iso8601

    # direct children
    contained = c
    yield dir, Size, contained.size
    if contained.size < 32 # provide some "lookahead" on small contained-containers. GET them directly for full contents
      contained.map{|c|
        if c.directory?
          child = c.descend # trailing-slash convention on containers
          yield dir, LDP+'contains', child
        else # doc
          yield dir, LDP+'contains', c.stripDoc # link to generic resource
        end
      }
    end

  end

    # POSTable container -> contained types
  Containers = {
    Wiki => SIOC+'WikiArticle',
    Forum            => SIOC+'Thread',
    SIOC+'Thread'    => SIOC+'BoardPost',
  }

end

class String

  def h; Digest::SHA1.hexdigest self end

  def tail; self[1..-1] end

  def t; match(/\/$/) ? self : self+'/' end

  def R
    R.new self
  end

  def slugify
    gsub /\W+/,'_'
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
