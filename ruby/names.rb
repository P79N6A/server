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

  # append operators
  def + u; R uri + u.to_s end
  alias_method :a, :+

  # nil -> String casted URI parts for construction
  def schemePart; scheme ? scheme + ':' : '' end
  def hostPart; host ? '//' + host : '' end
  def hierPart; path || '/' end
  def queryPart; query ? '?' + query : '' end
  def fragPart; fragment ? '#' + fragment : '' end
  def ext; (File.extname uri).tail || '' end
  def suffix; '.' + ext end
  def basename suffix = nil
    suffix ? (File.basename hierPart, suffix) : (File.basename hierPart) end
  def bare; basename suffix end

  # parent/child in context of hierPart
  def descend; uri.t.R end
  def child u; descend + u.to_s end
  def dirname; schemePart + hostPart + (File.dirname hierPart + queryPart) end
  def dir; dirname.R end
  def parentURI; R schemePart + hostPart + Pathname.new(hierPart).parent.to_s end

  # recursive paths up to root
  def hierarchy; hierPart.match(/^[.\/]+$/) ? [self] : [self].concat(parentURI.hierarchy) end
  def cascade; stripSlash.hierarchy end

  # URI <> POSIX-path
  VHosts = 'domain'
  def justPath; hierPart.R end
  def pathPOSIX; FSbase + '/' + pathPOSIXrel end
  def pathPOSIXrel
    if h = host
      VHosts + '/' + h + hierPart + queryPart
    else
      uri[0] == '/' ? uri.tail : uri
    end
  end
  def R.unPOSIX p, skip = R::BaseLen
    p[skip..-1].do{|p| R[ p.match(/^\/#{R::VHosts}\/+(.*)/).do{|m|'//'+m[1]} || p]}
  end

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
        u + 'index' # doc-name for root-path
      else
        u
      end}
  end

end

class String

  def R
    R.new self
  end

  def sh; Shellwords.escape self end

end
