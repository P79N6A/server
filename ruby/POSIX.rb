class Pathname
  def R; R::POSIX.path to_s.utf8 end
end
class WebResource
  module POSIX

    def self.splitArgs args
      args.shellsplit
    rescue
      puts "shell tokenization failed: #{args}"
      args.split(/\W/)
    end

    def link n
      send LinkMethod, n unless n.exist?
    rescue Exception => e
      puts e,e.class,e.message
    end
    def ln n
      FileUtils.ln   node.expand_path, n.node.expand_path
    end
    def ln_s n
      FileUtils.ln_s node.expand_path, n.node.expand_path
    end

    def readFile; File.open(localPath).read end

    def writeFile o; dir.mkdir; File.open(localPath,'w'){|f|f << o}; self end

    def touch
      dir.mkdir
      FileUtils.touch localPath
    end

    def size; node.size rescue 0 end

    def mtime; node.stat.mtime end
    alias_method :m, :mtime

    def delete
      node.delete
    end

    def exist?; node.exist? end
    alias_method :e, :exist?

    def symlink?; node.symlink? end

    def children; node.children.delete_if{|f|
        f.basename.to_s.index('.')==0
      }.map &:R end

    # dirname (resource reference)
    def dir; dirname.R if path end

    # dirname (string)
    def dirname; File.dirname path if path end

    # storage usage count
    def du; `du -s #{sh}| cut -f 1`.chomp.to_i end

    # create container
    def mkdir; FileUtils.mkdir_p localPath unless exist?; self end

    # fs-path -> URI
    def self.path p; p.sub(/^\./,'').gsub(' ','%20').gsub('#','%23').R end

    # URI -> fs-path
    def localPath; @path ||= (URI.unescape(path[0]=='/' ? '.' + path : path)) end

    # Pathname
    def node; @node ||= (Pathname.new localPath) end
    def directory?; node.directory? end
    def file?; node.file? end

    # shell-escaped path
    def shellPath; localPath.utf8.sh end
    alias_method :sh, :shellPath

    # path nodes
    def parts
      @parts ||= if path
                   if path[0]=='/'
                     path[1..-1]
                   else
                     path
                   end.split '/'
                 else
                   []
                 end
    end

    # basename of path component
    def basename; File.basename (path||'') end

    # strip native doc-format suffixes
    def stripDoc; R[uri.sub /\.(bu|e|html|json|log|md|msg|opml|ttl|txt|u)$/,''] end

    # name suffix
    def ext; (File.extname uri)[1..-1] || '' end

    # SHA2 hashed URI
    def sha2; to_s.sha2 end

  end

  include POSIX

  module Webize
    # file -> RDF
    def triplrFile
      s = path
      yield s, Title, basename
      size.do{|sz| yield s, Size, sz}
      mtime.do{|mt|
        yield s, Mtime, mt.to_i
        yield s, Date, mt.iso8601}
    end

    # directory -> RDF
    def triplrContainer
      s = path
      s = s + '/' unless s[-1] == '/'
      yield s, Type, R[Container]
      yield s, Size, children.size
      yield s, Title, basename
      mtime.do{|mt|
        yield s, Mtime, mt.to_i
        yield s, Date, mt.iso8601}
    end
  end

  module POSIX
    # hard-link capability test
    LinkMethod = begin
                   file = '~/.cache/web/link'.R
                   link = '~/.cache/web/link_'.R
                   # reset src-link state
                   file.touch unless file.exist?
                   # reset dest-link state
                   link.delete if link.exist?
                   # try link
                   file.ln link
                   :ln
                 rescue Exception => e
                   :ln_s
                 end
  end
end
