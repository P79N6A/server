watch __FILE__
class R

  # get

  def getIndexF p
    f = (self + p).node
    f.readlines.map{|l|R l.chomp} if f.exist?
  end

  def getIndexB p
    child(p).c.map{|n|
      R n.basename.gsub '|','/'}
  end

  # set

  # value stored in line of file
  def indexF p,o
    file = 'index/' + p.R.shorten.uri + o.R.path
    FileUtils.mkdir_p File.dirname file
    File.open(file,'a'){|f|f.write uri + "\n"}
  end

  # value stored in basename
  def indexB p,o
    dir = 'index/' + p.R.shorten.uri + o.R.path
    FileUtils.mkdir_p dir
    FileUtils.touch dir + '/' + uri.gsub('/','|')
  end

  alias_method :getIndex, :getIndexF
  alias_method :index,       :indexF

  GET['/cache'] = E404
  GET['/index'] = E404

  # bidirectional recursive-traverse on a predicate
  def walk pfull, pshort, g={}, v={}
    graph g       # resource-graph
    v[uri] = true # mark visited
    rel = g[uri].do{|s|s[pfull]} ||[] # forward-arcs (doc-graph)
    rev = R['/index/'+pshort].getIndex(self) ||[] # inverse arcs (index)
    rel.concat(rev).map{|r|
      v[r.uri] || (r.R.walk pfull,pshort,g,v)} # walk unvisited
    g # graph
  end

  # recursive child-nodes - depth-first, sorted
  def take *a
    node.take(*a).map &:R
  end

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
