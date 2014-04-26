def watch f
  R::Watch[f]=File.mtime f
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
  GET = {}
  POST = {}

  Watch = {}
  def self.dev
    Watch.each{|f,ts|
      if ts < File.mtime(f)
        load f
      end }
  end

  GREP_DIRS = []

  def + u; R uri + u.to_s end
  alias_method :a, :+
  def descend; R uri.t end
  def child u; descend + u.to_s end
  alias_method :as, :child

  def ext; (File.extname uri).tail || '' end
  def suffix; '.' + ext end
  def stripDoc;  R[uri.sub(Doc,'')] end
  def stripFrag; R[uri.split(/#/)[0]] end
  def stripSlash; uri[-1] == '/' ? R[uri[0..-2]] : self end
  def docroot; stripFrag.stripDoc.stripSlash end

  def hostPart; host ? '//' + host : '' end
  def hierPart; path || '/' end
  def queryPart; query ? '?' + query : '' end
  def justPath; hierPart.R end

  def basename s = nil
    s ? (File.basename hierPart, s) : (File.basename hierPart) end
  def dirname; hostPart + (File.dirname hierPart) end
  def dir; R dirname end
  def bare; basename suffix end

  def parent; R hostPart + Pathname.new(hierPart).parent.to_s end
  def hierarchy; %w{. /}.member?(hierPart) ? [self] : [self].concat(parent.hierarchy) end
  def cascade; stripSlash.hierarchy end

  VHosts = 'domain'
  def pathPOSIX; FSbase + '/' + pathPOSIXrel end
  def pathPOSIXrel
    if h = host
      VHosts + '/' + h + hierPart + queryPart
    else
      uri[0] == '/' ? uri.tail : uri
    end
  end

end

class String

  def dive; self[0..2]+'/'+self[3..-1] end

  def unpath skip = R::BaseLen
    self[skip..-1].do{|p|
      R[p.match(/^\/#{R::VHosts}\/+(.*)/).do{|m|'//'+m[1]} ||
        p]}
  end

  def R; R.new self end
  def sh; Shellwords.escape self end

end
