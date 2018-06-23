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

    # read file at location
    def readFile; File.open(localPath).read end

    # write file at location
    def writeFile o; dir.mkdir; File.open(localPath,'w'){|f|f << o}; self end

    # touch mapped node
    def touch
      dir.mkdir
      FileUtils.touch localPath
    end

    # erase mapped node
    def delete
      node.delete
    end

    # contained children minus hidden nodes
    def children; node.children.delete_if{|f|f.basename.to_s.index('.')==0}.map &:R end

    # dirname of mapped path
    def dir; dirname.R if path end
    def dirname; File.dirname path if path end

    # storage-space usage
    def du; `du -s #{sh}| cut -f 1`.chomp.to_i end

    # FIND on path component
    def find p
      (p && !p.empty?) ? `find #{sh} -ipath #{('*'+p+'*').sh} | head -n 2048`.lines.map{|pth|POSIX.path pth.chomp} : []
    end

    # GLOB on path component
    def glob; (Pathname.glob localPath).map &:R end

    # existence check on mapped fs-node
    def exist?; node.exist? end
    def symlink?; node.symlink? end
    alias_method :e, :exist?

    # create container
    def mkdir; FileUtils.mkdir_p localPath unless exist?; self end

    # size of mapped node
    def size; node.size rescue 0 end

    # mtime of mapped node
    def mtime; node.stat.mtime end
    alias_method :m, :mtime

    # storage path -> URI
    def self.path p; p.sub(/^\./,'').gsub(' ','%20').gsub('#','%23').R end

    # URI -> storage path
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

    # TLD of host
    def tld; host && host.split('.')[-1] || '' end

    # SHA2 hash of URI string
    def sha2; to_s.sha2 end

    # WebResource -> file(s)
    def selectNodes
      (if directory?
       if q.has_key?('f') && path!='/' # FIND
         found = find q['f']
         found
       elsif q.has_key?('q') && path!='/' # GREP
         grep q['q']
       else # LS
         if uri[-1] == '/'
           index = (self+'index.html').glob
           if !index.empty? && qs.empty? # static index
             index
           else
             [self, children]
           end
         else # outside container
           @r[:links][:down] = path + '/' + qs
           self
         end
       end
      else # GLOB can be overridden, or base-URI + extensions
        [self, ((match /[\*\{\[]/) ? self : (self + '.*')).glob ]
       end).justArray.flatten.compact.uniq.select &:exist?
    end

    # pattern -> file(s)
    def grep q
      args = POSIX.splitArgs q
      case args.size
      when 0
        return []
      when 2
        cmd = "grep -rilZ #{args[0].sh} #{sh} | xargs -0 grep -il #{args[1].sh}"
      when 3
        cmd = "grep -rilZ #{args[0].sh} #{sh} | xargs -0 grep -ilZ #{args[1].sh} | xargs -0 grep -il #{args[2].sh}"
      when 4
        cmd = "grep -rilZ #{args[0].sh} #{sh} | xargs -0 grep -ilZ #{args[1].sh} | xargs -0 grep -ilZ #{args[2].sh} | xargs -0 grep -il #{args[3].sh}"
      else
        pattern = args.join '.*'
        cmd = "grep -ril #{pattern.sh} #{sh}"
      end
      `#{cmd} | head -n 1024`.lines.map{|path| POSIX.path path.chomp}
    end
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

  module HTTP
    # redirect to time-dir
    def chronoDir ps
      time = Time.now
      loc = time.strftime(case ps[0][0].downcase
                          when 'y'
                            '%Y'
                          when 'm'
                            '%Y/%m'
                          when 'd'
                            '%Y/%m/%d'
                          when 'h'
                            '%Y/%m/%d/%H'
                          else
                          end)
      [303,@r[:Response].update({'Location' => '/' + loc + '/' + ps[1..-1].join('/') + qs}),[]]
    end

    def entity env, body = nil
      etags = env['HTTP_IF_NONE_MATCH'].do{|m|
        m.strip.split /\s*,\s*/ }
      if etags && (etags.include? env[:Response]['ETag'])
        [304, {}, []]
      else
        body = body ? body.call : self
        if body.class == WebResource # use Rack file-handler
          (Rack::File.new nil).serving((Rack::Request.new env),body.localPath).do{|s,h,b|
            [s,h.update(env[:Response]),b]}
        else
          [(env[:Status]||200), env[:Response], [body]]
        end
      end
    end

    def fileResponse
      @r[:Response].update({'Content-Type' => %w{text/html text/turtle}.member?(mime) ? (mime+'; charset=utf-8') : mime,
                            'ETag' => [m,size].join.sha2,
                            'Access-Control-Allow-Origin' => '*'
                           })
      @r[:Response].update({'Cache-Control' => 'no-transform'}) if mime.match /^(audio|image|video)/
      if q.has_key?('preview') && ext.match(/(mp4|mkv|png|jpg)/i)
        filePreview
      else
        entity @r
      end
    end

  end
  module HTML
    include URIs

    Markup[Container] = -> container , env, flip = 'bw' {
      flop = flip == 'bw' ? 'wb' : 'bw'
      uri = container.delete 'uri'
      container.delete Type
      name = (container.delete :name) || '' # basename
      title = container.delete Title
      # content may be singleton, array or URI-indexed hash
      contents = container.delete(Contains).do{|cs|
        cs.class == Hash ? cs.values : cs }.justArray
      blank = BlankLabel.member? name
      {class: 'container ' + flip, style: blank ? '' : 'margin-left: 1em',
       c: [({_: :span, class: "name #{title ? '' : 'basename'}", c: (title ? Markup[Title][title.justArray[0], env, uri.justArray[0]] : CGI.escapeHTML(name))} unless blank), # label
           if env['q'].has_key? 't'
             HTML.tabular contents, env, flip
           else # child nodes
             contents.map{|c|HTML.value(nil,c,env,flip)}
           end,
           (HTML.kv(container, env, flip) unless env['q'].has_key?('h'))
          ]}}

    # URI controls tree structure
    Group['tree'] = -> graph {
      tree = {}
      # select resource(s)
      (graph.class==Array ? graph : graph.values).map{|resource|
        cursor = tree
        r = resource.R
        # walk to document-graph location
        [r.host ? r.host.split('.').reverse : '',
         r.parts.map{|p|p.split '%23'}].flatten.map{|name|
          cursor[Type] ||= R[Container]
          cursor[Contains] ||= {}
           # create named-node if missing, advance cursor
          cursor = cursor[Contains][name] ||= {name: name,
                                               #Title => name,
                                               Type => R[Container]}}
        # reference to data
        if !r.fragment # document itself
          resource.map{|k,v|
            cursor[k] = cursor[k].justArray.concat v.justArray}
        else # resource local data
          cursor[Contains] ||= {}
          cursor[Contains][r.fragment] = resource
        end
      }; tree }

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
