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
        # persist slug across pages
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
        # inline small sets, limit large sets to pointers
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
    children = c
    yield dir, Size, children.size
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

  FileSet['rev'] = -> e,req,model { # find incoming-arcs via index-file
    (e.dir.child '.' + e.basename + '*.rev').glob.map{|rev|
      rev.node.readlines.map{|r|
        r.chomp.R.fileResources
      }}.flatten}

  FileSet['grep'] = -> e,q,m {
    q['q'].do{|query|
      e.env[:filters].push 'grep' unless q.has_key?('full')
      `grep -ril #{query.sh} #{e.sh} | head -n 255`.lines.map{|r|R.unPOSIX r.chomp}}}

  # grep in-memory graph
  Filter['grep'] = -> d,e {
    w = e.q['q']
    if w && w.size > 1
      e[:grep] = /#{w.scan(/[\w]+/).join '.*'}/i
      d.map{|u,r|
        if r.to_s.match e[:grep] # matching resource
          r[Type] = R['#grep-result']
        else
          d.delete u
        end}
    end}

  # set of search results
  ResourceSet['groonga'] = ->d,e,m{
    R.groonga.do{|ga|
      q = e['q']     # expression
      g = d.env.host # context

      # evaluate expression
      r = (q && !q.empty?) ? ga.select{|r|(r['graph'] == g) & r["content"].match(q)} : # query
      ga.select{|r| r['graph'] == g}                                 # or just ordered set
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
  
  # remove resource
  def unroonga
    g = R.groonga
    graph.keys.push(uri).map{|u|g[u].delete}
  end

  GET['/search'] = -> d,e {
    e.q['set'] = 'groonga'
    e[:container] = true
    e[:search] = true
    nil}

  # summarize contained-data on per-type basis
  Filter[Container] = -> g,e {
    e[:title] ||= e.R.path
    groups = {}
    g.map{|u,r|
      r.types.map{|type| # RDF types
        if v = Abstract[type] # summarizer
          groups[v] ||= {} # type-group
          groups[v][u] = r # resource -> group
        end}}
    groups.map{|fn,gr|fn[g,gr,e]}} # call summarizer(s)

  # set a request-level Title from the RDF-model
  Filter[Title] = -> g,e {
    g.values.find{|r|r[Title]}.do{|r|
       e[:title] ||= r[Title].justArray[0].to_s}}

  # wrap nodes in facet-containers
  Facets = -> m,e { # CSS rules are updated at runtime to control visible-set

    # facetized properties. can be multiple (commma-sep) URI-prefix shortened
    a = Hash[((e.q['a']||'dc:source').split ',').map{|a|
               [a.expand,{}]}]

    # generate statistics
    m.map{|s,r| # resources
      a.map{|p,_| # properties
        r[p].do{|o| # value
            o.justArray.map{|o| # values
              a[p][o] = (a[p][o]||0)+1 # count occurrences
            }}}}

    # mint a facet-identifier, greppable
    fid = -> f {
      f = f.respond_to?(:uri) ? f.uri : f.to_s
      f.sub('http','').gsub(/[^a-zA-Z]+/,'_')}

    # HTML
    [(H.css'/css/facets',true),
     (H.js'/js/facets',true),
     # filter control
     (a.map{|f,v|
       {class: :facet, facet: fid[f],
        c: [{_: :span, c: :filter, style: 'background-color: #000;color:#999'},
            {class: :predicate,
             c: f.shorten.split(':')[-1]},
            v.sort_by{|k,v|v}.reverse.map{|k,v| # sort by usage-weight
              name = k.respond_to?(:uri) ? ( k = k.R
                                             path = k.path
                                             frag = k.fragment
                                             if frag
                                               frag
                                             elsif !path || path == '/'
                                               k.host
                                             else
                                               path
                                             end
                                           ) : k.to_s
              {facet: fid[k], # facet
               c: [{_: :span, class: :count, c: v},' ',
                   {_: :span, name: name, class: :name, # label
                    c: name}]}}]}} unless m.keys.size==1),
     # content
     m.resources(e).map{|r| # each resource

       # lookup renderer
       type = r.types.find{|t|ViewA[t]}

       # build facet-identifiers
       a.map{|p,_|
         [fid[p], # p facet
          r[p].do{|o| # p+o facet
            o.justArray.map{|o|fid[o]}}].join ' '
       }.do{|f| # facet-id(s) bound
         [f.map{|o| '<div class="' + o + '">' }, # open wrapper
          ViewA[type ? type : BasicResource][r,e], # resource
          (0..f.size-1).map{|c|'</div>'}, "\n",  # close wrapper
         ]}}]}

  ViewGroup['#grep-result'] = -> g,e {
    c = {}
    w = e.q['q'].scan(/[\w]+/).map(&:downcase).uniq # words
    w.each_with_index{|w,i|c[w] = i} # enumerated words
    a = /(#{w.join '|'})/i           # highlight-pattern

    [{_: :style,
      c: ["h5 a {background-color: #fff;color:#000}\n h5 {margin:.3em}\n",
          c.values.map{|i|
            b = rand(16777216)                # word color
            f = b > 8388608 ? :black : :white # keep contrasty
            ".w#{i} {background-color: #{'#%06x' % b}; color: #{f}}\n"}]}, # word-color CSS

     g.map{|u,r| # matching resources
       r.values.flatten.select{|v|v.class==String}.map{|str| # string values
         str.lines.map{|ls|ls.gsub(/<[^>]+>/,'')}}.flatten.  # lines within strings
         grep(e[:grep]).do{|lines|                           # matching lines
         [{_: :h5, c: r.R.href}, # match URI
            lines[0..5].map{|line| # HTML-render of first 6 matching-lines
              line[0..400].gsub(a){|g|H({_: :span, class: "w w#{c[g.downcase]}", c: g})}}]}}]} # match

  ViewA[SearchBox] = -> r, e {
    [{_: :form, action: r.uri,
      c: {_: :input, name: :q, placeholder: :search, value: e.q['q']}},
     '<br>'     
    ]}
  ViewGroup[SearchBox] = -> d,e {d.values.map{|i|ViewA[SearchBox][i,e]}}

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
