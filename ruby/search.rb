class R
=begin
   indexer variants for triple, stream of triples and resource-reference

   outbound arcs from re(s)ource: (s p o) (s p _) (s _ o) (s _ _)
   in (s)ubject document, assuming this is findable, so write:
   - document at subject-URI mapped location

   inbound arcs to res(o)urce (_ p o) (_ _ o) not in its doc, so write:
   - reference to inbound-links doc in index-file stored alongside resource

=end

  def index o
    o = o.R.path
    R(File.dirname(o) + '/.' + File.basename(o) + '.rev').appendFile uri
  end

  def getIndex
    p = path
    f = R(File.dirname(p) + '/.' + File.basename(p) + '.rev').node
    f.readlines.map{|l|R l.chomp} if f.exist?
  end

  def indexStream triplr, &b
    docs = {}
    graph = fromStream({},triplr) # collect triples
    graph.map{|u,r| this = u.R    # visit resources
      doc = u.split('#')[0].R.stripDoc.a('.e').uri # storage location
      r[Date].do{|t|              # timestamp
        if this.host              # global-location resource
          # change doc location to our host as remote-host requests normally flow to someone else's server, not /domain
          slug = (u.sub(/https?:\/\//,'.').gsub(/\W/,'..').gsub(SlugStopper,'').sub(/\d{12,}/,'')+'.').gsub /\.+/,'.'
          time = t[0].to_s.gsub(/[-T]/,'/').sub(':','/').sub /(.00.00|Z)$/, '' # time-parts
          doc = "//localhost/#{time}#{slug}e"
        else # local resource
          # document already local path, no need to update location to localize

          # index inbound triples
          r[Re].justArray.map{|o|this.index o}

          # resource summary for index
          s = {'uri' => r.uri}   # summary resource
          [Type,Date,Creator,To,Title,DC+'identifier',Image].map{|p| r[p].do{|o| s[p]=o }} # preserved properties
          s[Content]=r[Content] if r.types.member? SIOC+'Tweet' # keep tiny content values
          summary = {r.uri => s} # summary graph

          # link summary to index container
          month = t[0][0..7].gsub '-','/' # month slug
          [To,Creator].map{|p|    # address predicates
          r[p].justArray.map{|a|  # address objects
            if a.respond_to? :uri # identifier please
              docs[a.R.dir.child(month+r.uri.sha1[0..12]+'.e').uri] = summary
            end}}
        end }
      # add resource to document
      docs[doc] ||= {}
      docs[doc][u] = r}

    # store documents
    docs.map{|doc,graph|
      doc = doc.R
      if doc.e
#        puts "cached #{doc}"
      elsif doc.justPath.e
#        puts "cached #{doc.justPath}"
      else
        doc.w graph, true
        puts "+ " + doc.path
      end}

    # emit triples if consumer exists
    graph.triples &b if b
    self
  end

  def indexResource options = {}
    g = RDF::Repository.load self, options
    g.each_graph.map{|graph|
      graph.query(RDF::Query::Pattern.new(:s,R[R::Date],:o)).first_value.do{|t| # find timestamp
        time = t.gsub(/[-T]/,'/').sub(':','/').sub /(.00.00|Z)$/, ''
        slug = (graph.name.to_s.sub(/https?:\/\//,'.').gsub(/[\W_]/,'..').gsub(SlugStopper,'').sub(/\d{12,}/,'')+'.').gsub(/\.+/,'.')[0..127].sub(/\.$/,'')
        doc =  R["//localhost/#{time}#{slug}.ttl"]
        # store document
        if doc.e
#          puts "cached #{doc}"
        elsif doc.justPath.e
#          puts "cached #{doc.justPath}"
        else
          doc.dir.mk
          RDF::Writer.open(doc.pathPOSIX){|f|f << graph}
          puts "+ " + doc.path
        end
        true
      } || puts("warning, #{uri} missing timestamp")
    }
    self
  rescue Exception => e
    puts uri, e.class, e.message , e.backtrace[0..2]
  end

  # find all connected resources
  def walk p, g={}, v={}
    graph g
    v[uri] = true # mark visited
    rel = g[uri].do{|s|s[p]} || [] # outbound arcs (from doc)
    rev = getIndex || []           # inbound arcs (from index)
    rel.concat(rev).map{|r|
      v[r.uri] || # visited
        r.R.walk(p,g,v)} # walk
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
      graph.delete u if r[Content].empty?}
    graph['#grep.CSS'] = {Content => H({_: :style, c: wordIndex.values.map{|i|
                                          ".w#{i} {background-color: #{'#%06x' % (rand 16777216)}; color: white}\n"}})}}

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

  def R
    R.unPOSIX to_s.utf8
  end

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
