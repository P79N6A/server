class R

  FileSet[Resource] = -> e,q,g {
    query = e.env['QUERY_STRING']

    # pagination on date-dirs
    e.path.match(/^\/([0-9]{4})\/([0-9]{2})\/([0-9]{2})\/(.*)?$/).do{|m|
      qs = query && !query.empty? && ('?' + query) || ''
      date = ::Date.parse "#{m[1]}-#{m[2]}-#{m[3]}"
      slug = m[4] || ''
      if slug.match(/^[0-2][0-9]\/?$/) # hour dirs
        hour = slug.to_i
        # next/prev hours
        np = date.strftime('/%Y/%m/%d/') + ('%02d' % (hour+1))
        pp = date.strftime('/%Y/%m/%d/') +  ('%02d' % (hour-1))
        # wraparound hours to next/prev days
        if hour == 0
          pp = (date - 1).strftime('/%Y/%m/%d/23/')
        elsif hour >= 23
          np = (date+1).strftime('/%Y/%m/%d/00/')
        end
        nPath = np
        pPath = pp
      else # day dirs
        pPath = (date-1).strftime('/%Y/%m/%d/')
        nPath = (date+1).strftime('/%Y/%m/%d/')
        # slug persists across pages, can be unexpanded glob or actual dir
        pp = pPath + slug
        np = nPath + slug
      end
      e.env[:nextEmpty] = true unless R['//' + e.env.host + nPath].e
      e.env[:prevEmpty] = true unless R['//' + e.env.host + pPath].e
      e.env[:Links][:prev] = pp + qs
      e.env[:Links][:next] = np + qs}

    if e.env[:container]
      htmlFile = e.a 'index.html'
      if e.env.format=='text/html' && !e.env['REQUEST_URI'].match(/\?/) && htmlFile.e
         [htmlFile.setEnv(e.env)] # found index.html, HTML requested, and no query -> use static-file
      else
        cs = e.c # child-nodes
        size = cs.size
        # inline small sets, reduce large-set data to pointers
        if size < 512 || q.has_key?('full')
          cs.map{|c|c.setEnv e.env}
          e.fileResources.concat cs
        else
          e.env[:summarized] = true
          e.fileResources
        end
      end
    else # resource(s)
      stars = e.to_s.scan('*').size
      if stars > 0 && stars < 3
        FileSet['glob'][e,q,g]
      else
        e.fileResources
      end
    end}

  FileSet['glob'] = -> path,query,model {
    if path.to_s.scan('*').size < 3 # limit wildcard usage
      path.env[:container] = true # enable multiple-resource summarizae
      path.glob.select(&:inside) # return paths inside server-root
    else
      []
    end}

  FileSet['find'] = -> e,q,m,x='' {
    e.exist? && q['q'].do{|q|
      r = '-iregex ' + ('.*' + q + '.*' + x).sh
      s = q['size'].do{|s| s.match(/^\d+$/) && '-size +' + s + 'M'} || ""
      t = q['day'].do{|d| d.match(/^\d+$/) && '-ctime -' + d } || ""
      `find #{e.sh} #{t} #{s} #{r} | head -n 255`.lines.map{|l|R.unPOSIX l.chomp}}}

  FileSet['page'] = -> d,r,m {
    # count
    c = ((r['c'].do{|c|c.to_i} || 12) + 1).max(1024).min 2
    # direction
    o = r.has_key?('asc') ? :asc : :desc

    (d.take c, o, r['offset'].do{|o|o.R}).do{|s| # get elements
      if r['offset'] && head = s[0] # create direction-reversing link
        d.env[:Links][:prev] = d.path + "?set=page&c=#{c-1}&#{o == :asc ? 'de' : 'a'}sc&offset=" + (URI.escape head.uri)
      end
      if edge = s.size >= c && s.pop # lookahead-node (and therefore another page) exists
        d.env[:Links][:next] = d.path + "?set=page&c=#{c-1}&#{o}&offset=" + (URI.escape edge.uri)
      end
      s }}

  GET['/today'] = -> e,r {[303, r[:Response].update({'Location'=> Time.now.strftime('/%Y/%m/%d/') + (e.path[7..-1] || '') + '?' + (r['QUERY_STRING']||'')}), []]}
  GET['/now'] = -> e,r {[303, r[:Response].update({'Location'=> Time.now.strftime('/%Y/%m/%d/%H/') + '?' + (r['QUERY_STRING']||'')}), []]}
  
  # internal storage directories not exposed to HTTP clients
  GET['/cache'] = E404
  GET['/domain'] = E404
  GET['/index'] = E404
  
  def triplrContainer
    dir = uri.t
    yield dir, Type, R[Container]
    yield dir, SIOC+'has_container', dir.R.dir unless path=='/'
    mt = mtime
    yield dir, Mtime, mt.to_i
    yield dir, Date, mt.iso8601
    contained = c
    yield dir, Size, contained.size
    contained.map{|c|
      if c.directory?
        child = c.descend # trailing-slash directory-URI convention
        yield dir, LDP+'contains', child
      else # file/leaf
        yield dir, LDP+'contains', c
      end
    } unless contained.size > 42
  end

  def triplrUriList
    open(pathPOSIX).readlines.map{|l|
      yield l.chomp, Type, R[Resource] }
  end

  # files describing a resource
  def fileResources
    r = [] # docs
    r.push self if e
    %w{e ht html md ttl txt}.map{|suffix|
      doc = docroot.a '.' + suffix
      r.push doc.setEnv(@r) if doc.e
    }
    r
  end

  def getIndex rev # match (? p o) using index-file
    p = path
    f = R(File.dirname(p) + '/.' + File.basename(p) + '.' + rev + '.rev').node
    f.readlines.map{|l|R l.chomp} if f.exist?
  end

  def index p, o # append to (s,p,o) index-file
    o = o.R
    path = o.path
    R(File.dirname(path) + '/.' + File.basename(path) + '.' + p.R.shorten + '.rev').appendFile uri
  end

  # find all connections
  def walk pfull, pshort, g={}, v={}
    graph g       # graph
    v[uri] = true # mark this as visited
    rel = g[uri].do{|s|s[pfull]} ||[] # outbound arcs (via doc)
    rev = getIndex(pshort) ||[]       # inbound arcs (via index)
    rel.concat(rev).map{|r|
      v[r.uri] || (r.R.walk pfull,pshort,g,v)} # walk unvisited
    g # graph
  end

  # recursive child-nodes
  def take *a
    node.take(*a).map &:R
  end

  FileSet['rev'] = -> e,req,model {

    # find resources with incoming-arcs, index-lookup
    (e.dir.child '.' + e.basename + '*.rev').glob.map{|rev|
      rev.node.readlines.map{|r|
        r.chomp.R.fileResources
      }}.flatten}

end

class Pathname

  def c # children
    return [] unless directory?
    children.delete_if{|n| n.basename.to_s.match /^\./}
  end

  # range traverse w/ offset + limit
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
