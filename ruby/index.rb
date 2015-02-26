#watch __FILE__
class R

  def [] p; predicate p end

  def []= p,o
    if o
      setFs p,o
    else
      (predicate p).map{|o|
        unsetFs p,o}
    end
  end

  def predicatePath p, s = true
    child s ? p.R.shorten : p
  end

  def objectPath o
    o,v = (if o.respond_to? :uri
             [o.uri.R.pathPOSIXrel, nil]
           else
             literal o
           end)
    [(child o), v] # (s,p,o) URI + literal
  end

  def po o
    indexPath.predicate o, false
  end

  def literal o
    str = nil
    ext = nil
    if o.class == String
      str = o;         ext='.txt'
    else
      str = o.to_json; ext='.json'
    end
    [str.h + ext, str]
  end

  def predicate p, short = true
    p = predicatePath p, short
    p.node.take.map{|n|
      if n.file? # literal
        o = n.R
        case o.ext
        when "json"
          o.r true
        else
          o.r
        end
      else # resource
        R.unPOSIX n.to_s, p.pathPOSIX.size
      end}
  end

  def setFs p, o, undo = false, short = true
    p = predicatePath p, short # s+p URI
    t,literal = p.objectPath o # s+p+o URI
    if o.class == R # resource
      if undo
        t.delete if t.e # undo
      else
        unless t.e
          if o.f    # file?
            o.ln t  # link
          else
            t.mk    # create dirent
          end
        end
      end
    else # literal
      if undo
        t.delete if t.e  # remove 
      else
        unless t.e # exists?
          t.dir.mk # init container
          t.w literal # write literal
        end
      end
    end
  end

  def unsetFs p,o
    setFs p,o,true
  end

  def index p,o
    return unless o.class == R
    p.R.indexPath.setFs o,self,false,false
  end

  def indexPath
    R['/index/'+shorten.uri]
  end

  GET['/cache'] = E404
  GET['/index'] = E404

  # return related (bidirectional) RDF-resources
  def walk p, g={}, v={}
    graph g       # resource-graph
    v[uri] = true # mark visited
    rel = g[uri].do{|s|s[p]} ||[] # outgoing (doc-graph)
    rev = p.R.po(self) || [] # incoming arcs (index)
    rel.concat(rev).map{|r|
      v[r.uri] || (r.R.walk p,g,v)} # walk unvisited
    g # accumulated graph
  end

  # return child-nodes
  def take *a
    node.take(*a).map &:R
  end

  # apply lambda to child-nodes
  def visit &f
    children.map{|child|
      yield child
      child.visit &f}
    nil
  end

  def node; Pathname.new pathPOSIX end
  def exist?;   node.exist? end
  def directory?; node.directory? end
  def file?;    node.file? end
  def symlink?; node.symlink? end
  def mtime;    node.stat.mtime if e end
  def realpath
    node.realpath
  rescue Exception => x
    puts x
  end
  def realURI; realpath.do{|p|p.R} end
  def size;     node.size end
  alias_method :e, :exist?
  alias_method :f, :file?
  alias_method :m, :mtime

end

class Pathname

  def R
    R.unPOSIX to_s.utf8
  end

  def c
    return [] unless directory?
    children.delete_if{|n| n.basename.to_s.match /^\./}
    rescue
      []
  end
  
  def take count=1000, direction=:desc, offset=nil
    offset = offset.pathPOSIX if offset

    ok = false    # in-range mark
    set=[]
    v,m={asc:      [:id,:>=],
        desc: [:reverse,:<=]}[direction]

    visit=->nodes{
      nodes.sort_by(&:to_s).send(v).each{|n|
        ns = n.to_s
        return if 0 >= count
        (ok || # already in-range
         !offset || # no offset required
         (sz = [ns,offset].map(&:size).min # size of compared region
          ns[0..sz-1].send(m,offset[0..sz-1]))) && # path-compare
        (if !(c = n.c).empty? # has children?
           visit.(c)          # visit children
         else
           count = count - 1 # decrement nodes-left count
           set.push n        # add node to result-set
           ok = true         # mark iterator as within range
        end )}}

    visit.(c)
    set
  end

end
