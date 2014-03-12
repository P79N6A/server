#watch __FILE__
class R

  # POSIX-fs based index of triples
  # 

  def index p,o
    return unless o.class == R
    p.R.indexPath.setFs o,self,false,false
  end

  # reachable graph along named predicate
  def walk p, g={}, v={}
#    puts "walk #{uri}"
    graph g       # cumulative graph
    v[uri] = true # visited mark

    rel = g[uri].do{|s|s[p]} ||[]
    rev = (p.R.po self) ||[]

    rel.concat(rev).map{|r|
      v[r.uri] || (r.R.walk p,g,v)}

    g
  end

  fn 'set/depth',->d,r,m{ # depth-first
    global = !r.has_key?('local')
    p = global ? d.pathSegment : d
    loc = global ? '' : '&local'
    c = ((r['c'].do{|c|c.to_i} || 12) + 1).max(1024) # an extra for next-page pointer
    o = r['d'] =~ /^a/ ? :asc : :desc            # direction
    (p.take c, o, r['offset'].do{|o|o.R}).do{|s| # take subtree
      first, last = s[0], s.size > 1 && s.pop
      desc, asc = o == :asc ? [first,last] : [last,first]
      u = m['#']
      u[Type] = R[HTTP+'Response']
      u[Prev] = {'uri' => d.uri + "?set=depth&c=#{c-1}&d=desc#{loc}&offset=" + (URI.escape desc.uri)} if desc
      u[Next] = {'uri' => d.uri + "?set=depth&c=#{c-1}&d=asc#{loc}&offset=" + (URI.escape asc.uri)} if asc
      s }}

  def po o
    indexPath.predicate o, false
  end

  def indexPath
    R['/index/'+shorten]
  end

  def take *a
    node.take(*a).map &:R
  end

  def randomLeaf
    c.empty? && self || c.r.randomLeaf
  end

  def R.graphProperties g
    g.values.select{|v|v.respond_to? :keys}.map(&:keys).flatten.uniq
  end

  fn 'set/randomLeaf',->d,e,m{[d.randomLeaf]}
  fn 'req/randomLeaf',->e,r{[302, {Location: e.randomLeaf.uri},[]]}

  # register a handler on /, add index support
  fn '/GET',->e,r{
    x = 'index.html'
    i = [e,e.pathSegment].compact.map{|e|e.as x}.find &:e # file exists?
    if i && !r['REQUEST_URI'].match(/\?/) # querystring implies query - skip file
      if e.uri[-1] == '/' # inside dir? (Apache mod_dir does this, most upstream servers don't)
        i.env(r).fileGET  # index file -> response
      else
        [301, {Location: e.uri.t}, []] # goto: dir/
      end
    else
      if r['REQUEST_URI'].match(/\/index.(html|jsonld|nt|n3|ttl|txt)$/) # request an index
        e.parent.as('').env(r). # eat virtual pathname, remain in dir 
          response # index response
      else
        e.response # default
      end
    end}

end


class Pathname

  def take count=1000, direction=:desc, offset=nil
    offset = offset.d if offset

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
         (sz = [ns,offset].map(&:size).min
          ns[0..sz-1].send(m,offset[0..sz-1]))) &&
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
