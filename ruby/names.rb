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
  def == u;     to_s == u.to_s end
  def <=> c;    to_s <=> c.to_s end

  # append operators
  def + u; R uri + u.to_s end
  alias_method :a, :+

  # URI-parts with nil -> empty-string
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

  # parent/child relationships in hierPart
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
  def node; Pathname.new pathPOSIX end
  def R.unPOSIX p, skip = R::BaseLen
    p[skip..-1].do{|p| R[ p.match(/^\/#{R::VHosts}\/+(.*)/).do{|m|'//'+m[1]} || p]}
  end
  def inside; node.expand_path.to_s.index(FSbase) == 0 end
  alias_method :d, :pathPOSIX

  # strip variant-suffixes -> base-URI
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

  def exist?;   node.exist? end
  def directory?; node.directory? end
  def file?;    node.file? end
  def symlink?; node.symlink? end
  def mtime;    node.stat.mtime if e end
  def realpath; node.realpath rescue nil end
  def sh;       d.force_encoding('UTF-8').sh end # shell-escaped POSIX path
  def size;     node.size end
  alias_method :e, :exist?
  alias_method :f, :file?
  alias_method :m, :mtime

  def triplrInode dirChildren=true, &f
    if directory?
      d = descend.uri
      yield d, Stat+'size', size
      yield d, Stat+'mtime', mtime.to_i
      [R[Stat+'Directory'], R[LDP+'BasicContainer']].map{|type| yield d, Type, type}
      c.sort.map{|c|c.triplrInode false, &f} if dirChildren

    elsif symlink?
      [R[Stat+'Link'], Resource].map{|type| yield uri, Type, type}
      yield uri, Stat+'mtime', Time.now.to_i
      yield uri, Stat+'size', 0
      readlink.do{|t| yield uri, Stat+'target', t.stripDoc}

    else
      yield uri, Type, R[Stat+'File']
      yield uri, Stat+'size', size
      yield uri, Stat+'mtime', mtime.to_i
    end
  end

  # balanced-prefixes container-names
  def R.dive s
    s[0..2] + '/' + s[3..-1]
  end

end

class String

  def R
    R.new self
  end

  def sh; Shellwords.escape self end

end
