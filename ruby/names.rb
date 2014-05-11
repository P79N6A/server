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

  View = {}
  FileSet = {}
  ResourceSet = {}
  Render = {}
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
  def stripDoc;  uri.sub(Doc,'').R end
  def stripFrag; uri.split(/#/)[0].R end
  def stripSlash; (uri[-1] == '/' && path != '/') ? uri[0..-2].R : self end
  def docroot; stripFrag.stripDoc.stripSlash end

  def hostPart; host ? '//' + host : '' end
  def hierPart; path || '/' end
  def fragPart; fragment ? '#' + fragment : '' end
  def queryPart; query ? '?' + query : '' end

  def justPath; hierPart.R end

  def basename suffix = nil
    suffix ? (File.basename hierPart, suffix) : (File.basename hierPart)
  end
  def bare; basename suffix end

  def dirname; hostPart + (File.dirname hierPart) end
  def dir; dirname.R end

  def parent; R hostPart + Pathname.new(hierPart).parent.to_s end
  def hierarchy; hierPart.match(/^[.\/]+$/) ? [self] : [self].concat(parent.hierarchy) end
  def cascade; stripSlash.hierarchy end

  def bindHost
    return self if !hierPart.match(/^\//)
    R[R[@r['SCHEME']+'://'+@r['SERVER_NAME']].join(uri).to_s]
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

end

class String

  def R
    R.new self
  end

  def sh; Shellwords.escape self end

end
