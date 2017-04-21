class R

  Set[Resource] = -> re {
    query = re.env['QUERY_STRING']
    qs = query && !query.empty? && ('?' + query) || ''

    # date parts
    dp = []
    parts = re.path.tail.split '/'
    while parts[0] && parts[0].match(/^[0-9]+$/) do
      dp.push parts.shift.to_i
    end
    n = nil; p = nil
    case dp.length
    when 1 # Y
      year = dp[0]
      n = '/' + (year + 1).to_s
      p = '/' + (year - 1).to_s
    when 2 # Y-m
      year = dp[0]
      m = dp[1]
      n = m >= 12 ? "/#{year + 1}/#{01}/" : "/#{year}/#{'%02d' % (m + 1)}/"
      p = m <=  1 ? "/#{year - 1}/#{12}/" : "/#{year}/#{'%02d' % (m - 1)}/"
    when 3 # Y-m-d
      day = ::Date.parse "#{dp[0]}-#{dp[1]}-#{dp[2]}" rescue Time.now
      p = (day-1).strftime('/%Y/%m/%d/')
      n = (day+1).strftime('/%Y/%m/%d/')
    when 4 # Y-m-d-H
      day = ::Date.parse "#{dp[0]}-#{dp[1]}-#{dp[2]}" rescue Time.now
      hour = dp[3]
      p = hour <=  0 ? (day - 1).strftime('/%Y/%m/%d/23/') : (day.strftime('/%Y/%m/%d/')+('%02d/' % (hour-1)))
      n = hour >= 23 ? (day + 1).strftime('/%Y/%m/%d/00/') : (day.strftime('/%Y/%m/%d/')+('%02d/' % (hour+1)))
    end
    re.env[:Links][:prev] = p + parts.join('/') + qs if p && R['//' + re.host + p].e
    re.env[:Links][:next] = n + parts.join('/') + qs if n && R['//' + re.host + n].e

    # directory handler
    if re.path[-1] == '/'
      htmlFile = re.a 'index.html'
       # HTML requested, file exists, and no query
      if re.format=='text/html' && !re.env['REQUEST_URI'].match(/\?/) && htmlFile.e
         [htmlFile.setEnv(re.env)] # static response
      else
        if re.env[:grep]
          `grep -ril #{re.q['q'].sh} #{re.sh} | head -n 255`.lines.map{|r|R.unPOSIX r.chomp}
        else
          cs = re.c # child-nodes
          if cs.size < 512
            cs.map{|c|c.setEnv re.env}
            re.fileResources.concat cs
          else
            re.fileResources
          end
        end
      end
    else # glob set
      if re.env[:glob]
        re.glob.select &:inside
      else # base set
        re.fileResources
      end
    end}

  Set['find'] = -> e {
    e.exist? && e.q['q'].do{|q|
      r = '-iregex ' + ('.*' + q + '.*').sh
      s = q['size'].do{|s| s.match(/^\d+$/) && '-size +' + s + 'M'} || ""
      t = q['day'].do{|d| d.match(/^\d+$/) && '-ctime -' + d } || ""
      `find #{e.sh} #{t} #{s} #{r} | head -n 255`.lines.map{|l|R.unPOSIX l.chomp}}}

  Set['page'] = -> d {
    # count
    c = ((d.q['c'].do{|c|c.to_i} || 12) + 1).max(1024).min 2
    # direction
    o = d.q.has_key?('asc') ? :asc : :desc
    (d.take c, o, d.q['offset'].do{|o|o.R}).do{|s| # search
      if d.q['offset'] && head = s[0] # direction-reversal link
        d.env[:Links][:prev] = d.path + "?set=page&c=#{c-1}&#{o == :asc ? 'de' : 'a'}sc&offset=" + (URI.escape head.uri)
      end
      if edge = s.size >= c && s.pop # lookahead node, and therefore another page, exists. point to it
        d.env[:Links][:next] = d.path + "?set=page&c=#{c-1}&#{o}&offset=" + (URI.escape edge.uri)
      end
      s }}

  GET['/d']   = -> e {[303, e.env[:Response].update({'Location'=> Time.now.strftime('/%Y/%m/%d/') + (e.path[3..-1] || '') + '?' + (e.env['QUERY_STRING']||'')}), []]}
  GET['/now']   = -> e {[303, e.env[:Response].update({'Location'=> Time.now.strftime('/%Y/%m/%d/%H/') + (e.path[5..-1] || '') + '?' + (e.env['QUERY_STRING']||'')}), []]}

  def triplrContainer
    dir = uri.t
    yield dir, Type, R[Container]
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

  def fileResources
    r = [] # docs
    r.push self if e
    %w{e ht html md ttl txt}.map{|suffix|
      doc = docroot.a '.' + suffix
      r.push doc.setEnv(@r) if doc.e
    }
    r
  end

  def getIndex rev # find (? p o) triple
    p = path
    f = R(File.dirname(p) + '/.' + File.basename(p) + '.' + rev + '.rev').node
    f.readlines.map{|l|R l.chomp} if f.exist?
  end

=begin
   indexers. variants for triple, stream of triples and resource reference
   using RDF library and graph-database is of course an option,
   the following methods allow us to fulfill index needs using only the fs

   outgoing arcs from re(s)ource: (s p o) (s p _) (s _ o) (s _ _) patterns
    matchable in subject doc-graph, assuming this is findable, so write:
   - document to local store at subject-URI derived location

   incoming arcs to res(o)urce: (_ p o) (_ _ o) patterns
   - incoming triples to URI-list file stored alongside resource

=end

  # index a triple
  def index p, o # (s)ubject is implicit "self" argument
    o = o.R.path
    # append to incoming-link index
    R(File.dirname(o) + '/.' + File.basename(o) + '.' + p.R.shorten + '.rev').appendFile uri
  end

  # index resources in stream
  def indexStream triplr, &b
    docs = {}
    graph = fromStream({},triplr) # collect triples
    graph.map{|u,r| this = u.R    # visit resources
      doc = this.jsonDoc.uri      # resource-storage URI
      r[Date].do{|t|              # timestamp for timeline link and address index
        if this.host              # global-location resource
          # link to location on our host as remote-host requests flow to someone else's server, not /domain
          # note daemon will serve cache of remote resource with a crafted Host header, if you have cache/proxy ideas
          slug = (u.sub(/https?:\/\//,'.').gsub(/\W/,'..').gsub(SlugStopper,'').sub(/\d{12,}/,'')+'.').gsub /\.+/,'.'
          time = t[0].to_s.gsub(/[-T]/,'/').sub(':','/').sub /(.00.00|Z)$/, '' # datetime slug
          doc = "//localhost/#{time}#{slug}e"
        else # local resource
          # document already has a local path

          # summarize resource for index entry
          s = {'uri' => r.uri}   # summary resource
          [Type,Date,Creator,To,Title,DC+'identifier',Image].map{|p| r[p].do{|o| s[p]=o }} # preserved properties
          s[Content]=r[Content] if r.types.member? SIOC+'Tweet' # keep tiny content values
          summary = {r.uri => s} # summary graph

          # point to resource in address-month index
          month = t[0][0..7].gsub '-','/' # month slug
          [To,Creator].map{|p|    # address predicates
          r[p].justArray.map{|a|  # address objects
            if a.respond_to? :uri # identifier please
              a = a.R             # address resource
              dir = a.fragment ? a.path.R : a # index path
              docs[dir.child(month+r.uri.h[0..12]+'.e').uri] = summary # add index-entry for writing
            end}}

          # index message-reference backlinks, for discussion finding
          r[Re].justArray.map{|o|this.index Re,o}
        end }
      # add resource for writing
      docs[doc] ||= {}
      docs[doc][u]=r }
    # store documents
    docs.map{|doc,graph| doc = doc.R
      unless doc.e
        doc.w graph, true
        puts "+ " + doc.path
      end}
    graph.triples &b if b # emit triples
    self
  end

  # index resource
  def indexResource options = {}
    g = RDF::Repository.load self, options
    g.each_graph.map{|graph|
      graph.query(RDF::Query::Pattern.new(:s,R[R::Date],:o)).first_value.do{|t| # find timestamp
        time = t.gsub(/[-T]/,'/').sub(':','/').sub /(.00.00|Z)$/, ''
        slug = (graph.name.to_s.sub(/https?:\/\//,'.').gsub(/[\W_]/,'..').gsub(SlugStopper,'').sub(/\d{12,}/,'')+'.').gsub(/\.+/,'.')[0..96].sub(/\.$/,'')
        doc =  R["//localhost/#{time}#{slug}.ttl"]
        unless doc.e
          doc.dir.mk
          RDF::Writer.open(doc.pathPOSIX){|f|f << graph} # store resource
          puts "+ " + doc.stripDoc
        end
        true
      } || puts("warning, #{uri} missing timestamp")
    }
    self
  rescue Exception => e
    puts uri, e.class, e.message , e.backtrace[0..2]
  end

  # find all connected resources
  def walk pfull, pshort, g={}, v={}
    graph g
    v[uri] = true # mark visited
    rel = g[uri].do{|s|s[pfull]} ||[] # outbound arcs (from doc)
    rev = getIndex(pshort) ||[]       # inbound arcs (from index)
    rel.concat(rev).map{|r|
      v[r.uri] || # visited
        r.R.walk(pfull,pshort,g,v)} # walk
    g # accumulated graph
  end

  Grep = -> graph, re {
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
            H({_: :span, class: "w w#{wordIndex[g.downcase]}", c: g})}}}
      graph.delete u if r[Content].empty?
    }
    graph['#grep.CSS'] = {Content => H({_: :style,
                                       c: wordIndex.values.map{|i|
                                         bg = rand 16777216
                                         fg = bg > 8388608 ? :black : :white
                                         ".w#{i} {background-color: #{'#%06x' % bg}; color: #{fg}}\n"}})}}

  Summarize = -> g,e {
    groups = {}
    g.map{|u,r|
      r.types.map{|type| # each type
        if v = Abstract[type] # summarizer function
          groups[v] ||= {} # create type-group
          groups[v][u] = r # resource -> group
        end}}
    groups.map{|fn,gr|fn[g,gr,e]}} # call summarizer

  # recursive child-nodes, work happens in Pathname context, see below
  def take *a
    node.take(*a).map &:R
  end
  
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
