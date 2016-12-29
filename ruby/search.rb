#watch __FILE__
class R

  FileSet[Resource] = -> re {
    query = re.env['QUERY_STRING']

    re.path.match(/^\/([0-9]{4})\/([0-9]{2})\/([0-9]{2})\/(.*)?$/).do{|m| # day dirs
      qs = query && !query.empty? && ('?' + query) || ''
      date = ::Date.parse "#{m[1]}-#{m[2]}-#{m[3]}"
      slug = m[4] || ''
      if slug.match(/^[0-2][0-9]\/?$/) # hour dirs
        hour = slug.to_i
        # next/prev hours
        np = date.strftime('/%Y/%m/%d/') + ('%02d' % (hour+1))
        pp = date.strftime('/%Y/%m/%d/') +  ('%02d' % (hour-1))
        # wraparound to next/prev day
        if hour == 0
          pp = (date - 1).strftime('/%Y/%m/%d/23/')
        elsif hour >= 23
          np = (date + 1).strftime('/%Y/%m/%d/00/')
        end
        nPath = np
        pPath = pp
      else
        pPath = (date-1).strftime('/%Y/%m/%d/')
        nPath = (date+1).strftime('/%Y/%m/%d/')
        # persist slug across pages
        pp = pPath + slug
        np = nPath + slug
      end
      re.env[:nextEmpty] = true unless R['//' + re.host + nPath].e
      re.env[:prevEmpty] = true unless R['//' + re.host + pPath].e
      re.env[:Links][:prev] = pp + qs
      re.env[:Links][:next] = np + qs}

    if re.path[-1] == '/'
      htmlFile = re.a 'index.html'
      if re.format=='text/html' && !re.env['REQUEST_URI'].match(/\?/) && htmlFile.e
         [htmlFile.setEnv(re.env)] # found index.html, HTML requested, and no query -> use static-file
      else
        cs = re.c # child-nodes
        size = cs.size
        # inline small sets, limit large sets to pointers
        if size < 512 || re.q.has_key?('full')
          cs.map{|c|c.setEnv re.env}
          re.fileResources.concat cs
        else
          re.env[:summarized] = true
          re.fileResources
        end
      end
    else
      stars = re.uri.scan('*').size
      if stars > 0 && stars <= 3
        FileSet['glob'][re]
      else
        re.fileResources
      end
    end}

  FileSet['glob'] = -> r {
    if r.uri.scan('*').size <= 3 # limit wildcard usage
      r.glob.select(&:inside) # match and jail matches
    else
      []
    end}

  FileSet['find'] = -> e {
    e.exist? && e.q['q'].do{|q|
      r = '-iregex ' + ('.*' + q + '.*').sh
      s = q['size'].do{|s| s.match(/^\d+$/) && '-size +' + s + 'M'} || ""
      t = q['day'].do{|d| d.match(/^\d+$/) && '-ctime -' + d } || ""
      `find #{e.sh} #{t} #{s} #{r} | head -n 255`.lines.map{|l|R.unPOSIX l.chomp}}}

  FileSet['page'] = -> d {
    # count
    c = ((d.q['c'].do{|c|c.to_i} || 12) + 1).max(1024).min 2
    # direction
    o = d.q.has_key?('asc') ? :asc : :desc

    (d.take c, o, d.q['offset'].do{|o|o.R}).do{|s| # get elements
      if d.q['offset'] && head = s[0] # create direction-reversing link
        d.env[:Links][:prev] = d.path + "?set=page&c=#{c-1}&#{o == :asc ? 'de' : 'a'}sc&offset=" + (URI.escape head.uri)
      end
      if edge = s.size >= c && s.pop # lookahead-node (and therefore another page) exists
        d.env[:Links][:next] = d.path + "?set=page&c=#{c-1}&#{o}&offset=" + (URI.escape edge.uri)
      end
      s }}

  GET['/today'] = -> e {[303, e.env[:Response].update({'Location'=> Time.now.strftime('/%Y/%m/%d/') + (e.path[7..-1] || '') + '?' + (e.env['QUERY_STRING']||'')}), []]}
  GET['/now'] = -> e {[303, e.env[:Response].update({'Location'=> Time.now.strftime('/%Y/%m/%d/%H/') + '?' + (e.env['QUERY_STRING']||'')}), []]}
  
  # internal storage not exposed on HTTP
  GET['/cache'] = GET['/domain'] = GET['/index'] = -> e {e.notfound}

  def triplrContainer
    dir = uri.t
    yield dir, Type, R[Container]
    yield dir, SIOC+'has_container', dir.R.dir unless path=='/'
    mt = mtime
    yield dir, Mtime, mt.to_i
    yield dir, Date, mt.iso8601
    children = c
    yield dir, Size, children.size
  end

  def triplrFile
    yield uri, Type, R[Stat+'File']
    mt = mtime
    yield uri, Mtime, mt.to_i
    yield uri, Date, mt.iso8601
    yield uri, Size, size
  end

  def triplrArchive
    yield uri, Type, R[Stat+'CompressedFile']
    mt = mtime
    yield uri, Mtime, mt.to_i
    yield uri, Date, mt.iso8601
    yield uri, Size, size
  end

  def triplrUriList
    open(pathPOSIX).readlines.map{|l|
      yield l.chomp, Type, R[Resource] }
  end

  def fileResources
    r = [] # docs
    r.push self if e
    %w{e ht html md ttl txt}.map{|suffix|
      doc = docroot.a '.' + suffix
      r.push doc.setEnv(@r) if doc.e
    }
    r
  end

  def getIndex rev # lookup (? p o) in index-file
    p = path
    f = R(File.dirname(p) + '/.' + File.basename(p) + '.' + rev + '.rev').node
    f.readlines.map{|l|R l.chomp} if f.exist?
  end

  def index p, o # append (s,p,o) to reverse-link index
    o = o.R
    path = o.path
    R(File.dirname(path) + '/.' + File.basename(path) + '.' + p.R.shorten + '.rev').appendFile uri
  end

  # find all connected resources
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

  FileSet['rev'] = -> e { # find incoming-arcs via index-file
    (e.dir.child '.' + e.basename + '*.rev').glob.map{|rev|
      rev.node.readlines.map{|r|
        r.chomp.R.fileResources
      }}.flatten}

  FileSet['grep'] = -> e {
    e.q['q'].do{|query|
      e.env[:filters].push 'grep' unless e.q.has_key?('full')
      `grep -ril #{query.sh} #{e.sh} | head -n 255`.lines.map{|r|R.unPOSIX r.chomp}}}

  Filter['grep'] = -> graph, re {
    wordIndex = {}
    query = re.q['q']
    words = query.scan(/[\w]+/).map(&:downcase).uniq
    words.each_with_index{|word,i|wordIndex[word] = i}
    pattern = /#{words.join '.*'}/i
    highlight = /(#{words.join '|'})/i
    graph.map{|u,r|
      r.values.flatten.select{|v|v.class==String}.map(&:lines).flatten.map{|l|l.gsub(/<[^>]+>/,'')}.grep(pattern).do{|lines| # match lines
        r[Content] = []
        lines[0..5].map{|line|
          r[Content].unshift line[0..400].gsub(highlight){|g|
            H({_: :span, class: "w w#{wordIndex[g.downcase]}", c: g})}}}}

    graph['#grepCSS'] = {Content => H({_: :style,
                                       c: wordIndex.values.map{|i|
                                         bg = rand 16777216
                                         fg = bg > 8388608 ? :black : :white
                                         ".w#{i} {background-color: #{'#%06x' % bg}; color: #{fg}}\n"}})}}

  ResourceSet['groonga'] = ->d{ # third-party search-engine handler
    e = d.q
    q = e['q'] # expression
    q && R.groonga.do{|ga|
      g = d.host # context

      # evaluate expression
      r = ga.select{|r|(r['graph'] == g) & r["content"].match(q)}
      start = e['start'].do{|c| c.to_i.max(r.size - 1).min 0 } || 0  # offset
      c = (e['c']||e['count']).do{|c|c.to_i.max(10000).min(0)} || 16 # count
      down = r.size > start+c                                        # prev
      up   = !(start<=0)                                             # next

      # sort
      r = r.sort(e.has_key?('relevance') ? [["_score"]] : [["time","descending"]],
                 :offset =>start, :limit =>c)

      # paginate
      d.env[:Links][:next] = '/search/' + {'q' => q,
                                           'start' => start + c,
                                           'c' => c}.qs if down
      d.env[:Links][:prev] = '/search/' + {'q' => q,
                                           'start' => start - c,
                                           'c' => c}.qs if up
      # return first-class resources
      r.map{|r| r['.uri'].R }}}

  # open db at location
  def groonga
    return Groonga::Database.open pathPOSIX if e # exists
    dir.mk                                       # create
    Groonga::Database.create(:path => pathPOSIX)
    Groonga::Schema.define{|s|
      s.create_table("R",:type => :hash,:key_type => "ShortText"){|t|
        t.short_text "uri"
        t.short_text "graph"
        t.text "content"
        t.time "time" }
      s.create_table("Bigram",
                     :type => :patricia_trie,
                     :normalizer => :NormalizerAuto,
                     :default_tokenizer => "TokenBigram"){|t|
                                  %w{uri graph content}.map{|c| t.index("R." + c) }}}
  end

  # db handle
  def R.groonga
    @groonga ||=
      (begin require 'groonga'
         R['/index/groonga'].groonga
         Groonga["R"]
       rescue LoadError => e
         puts e
       end)
  end
  
  # add resource to index
  def roonga graph="localhost", m = self.graph
    R.groonga.do{|g| # db
      m.map{|u,i|
        puts '+ '+(if u.match(/^\/[^\/]/)
                   "http://#{graph}#{u}"
                  else
                    u
                   end)
          r = g[u] || g.add(u) # create or load entry
        r.uri = u            # update data
        r.graph = graph.to_s
        r.content = i.to_json
        r.time = i[R::Date].do{|t|t[0].to_time}
      }}
    self
  end
  
  # remove resource from index
  def unroonga
    g = R.groonga
    graph.keys.push(uri).map{|u|g[u].delete}
  end

  # summarize contained-data on per-type basis
  Filter[Container] = -> g,e {
    e.env[:title] ||= e.path
    groups = {}
    g.map{|u,r|
      r.types.map{|type| # RDF types
        if v = Abstract[type] # summarizer
          groups[v] ||= {} # type-group
          groups[v][u] = r # resource -> group
        end}}
    groups.map{|fn,gr|fn[g,gr,e]}} # call summarizer(s)

  # find request-level Title in the RDF-model
  Filter[Title] = -> g,e {
    g.values.find{|r|r[Title]}.do{|r|
       e.env[:title] ||= r[Title].justArray[0].to_s}}

  SearchBox = -> env {
    {_: :form,
     c: {_: :input, name: :q, placeholder: :search, value: env.q['q']}}}

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
