def watch f
  R::Watch[f] = File.mtime f
  puts 'dev '+f end

def R uri
  R.new uri
end

class R

  def R uri = nil
    uri ? R.new(uri) : self
  end

  def R.[] uri; R.new uri end

  FileSet = {}
  ResourceSet = {}
  Render = {}
  View = {}
  JSONview = {}
  Watch = {}
  GET = {}
  POST = {}

  def self.dev
    Watch.each{|f,ts|
      if ts < File.mtime(f)
        load f
      end }
  end

  GREP_DIRS = []

  def + u; R uri + u.to_s end
  alias_method :a, :+
  def descend; uri.t.R end
  def child u; descend + u.to_s end

  def ext; (File.extname uri).tail || '' end
  def suffix; '.' + ext end

  def schemePart; scheme ? scheme + ':' : '' end
  def hostPart; host ? '//' + host : '' end
  def hierPart; path || '/' end
  def queryPart; query ? '?' + query : '' end
  def justPath; hierPart.R end

  def basename suffix = nil
    suffix ? (File.basename hierPart, suffix) : (File.basename hierPart)
  end
  def bare; basename suffix end

  def dirname; schemePart + hostPart + (File.dirname hierPart + queryPart) end
  def dir; dirname.R end

  def parentURI; R schemePart + hostPart + Pathname.new(hierPart).parent.to_s end
  def hierarchy; hierPart.match(/^[.\/]+$/) ? [self] : [self].concat(parentURI.hierarchy) end
  def cascade; stripSlash.hierarchy end

  def bindHost
    return self if !hierPart.match(/^\//)
    R[(lateHost.join uri).to_s]
  end

  def base
    bindHost.stripDoc.setEnv @r
  end

  VHosts = 'domain'
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

  def R.dive s
    s[0..2] + '/' + s[3..-1]
  end

  def docroot # -frag -ext -slash
    stripFrag.stripDoc.stripSlash.do{|u|
      if u.path == '/'
        u + 'index'
      else
        u
      end}
  end

  def stripFrag
    R uri.split(/#/)[0]
  end

  def stripDoc
    R uri.sub Doc, ''
  end

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

end

class String

  def R
    R.new self
  end

  def sh; Shellwords.escape self end

end
