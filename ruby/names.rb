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
  VHosts = 'domain'

  def appendURI u; R uri + u.to_s end
  alias_method :a, :appendURI
  alias_method :+, :appendURI
  def as u; descend + u.to_s end
  def descend; R uri.t end

  def ext; (File.extname uri).tail || '' end
  def suffix; '.' + ext end
  def stripDoc;  R[uri.sub(/\.(atom|e|html|json(ld)?|n3|nt|rdf|ttl|txt)$/,"")] end
  def stripFrag; R[uri.split(/#/)[0]] end
  def stripSlash; uri[-1] == '/' ? R[uri[0..-2]] : self end
  def docroot; stripFrag.stripDoc.stripSlash end

  def hostPart; host ? '//' + host : '' end
  def pathPart; path || '/' end
  def justPath; pathPart.R end

  def basename suffix = nil
    suffix ? (File.basename to_s, suffix) : (File.basename to_s) end
  def dirname; hostPart + (path.do{|p|File.dirname p} || '/') end
  def bare; basename suffix end
  alias_method :base, :basename
  alias_method :dir,  :dirname

  def parent;   R Pathname.new(uri).parent end
  def parents;  parent.do{|p|p.uri.match(/^[.\/]+$/) ? [p] : [p].concat(p.parents)} end
  def cascade;  [stripSlash].concat parents end

  def pathPOSIX; FSbase + '/' + pathPOSIXrel end
  def pathPOSIXrel
    if h = host # vhost directories
      VHosts + '/' + h + (path ? path : '') + (query ? '?'+query : '')
    else # absolute paths relative to server root
      uri[0] == '/' ? uri.tail : uri
    end
  end

end

class FalseClass
  def do; false end
end

class Hash
  def R; R.new uri end
  def uri; self["uri"]||"" end
  alias_method :url, :uri
  alias_method :maybeURI, :uri
end

class NilClass
  def do; nil end
end

class Object
  def id; self end
  def do; yield self end
  def maybeURI; nil end
  def justArray; [self] end
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
