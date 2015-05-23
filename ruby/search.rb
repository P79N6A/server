#watch __FILE__
class R

  # get index (fs)
  # on-filesystem RDF-link indexing

  def getIndex rev # match (? p o)
    p = path
    f = R(File.dirname(p) + '/.' + File.basename(p) + '.' + rev + '.rev').node
    f.readlines.map{|l|R l.chomp} if f.exist?
  end
  def index p, o # index (s p o)
    o = o.R
    path = o.path
    R(File.dirname(path) + '/.' + File.basename(path) + '.' + p.R.shorten + '.rev').appendFile uri
  end

  GET['/cache'] = E404
  GET['/index'] = E404

  # bidirectional recursive-traverse on a predicate
  def walk pfull, pshort, g={}, v={}
    graph g       # resource-graph
    v[uri] = true # mark visited
    rel = g[uri].do{|s|s[pfull]} ||[] # forward-arcs (doc-graph)
    rev = getIndex(pshort) ||[] # inverse arcs (index)
    rel.concat(rev).map{|r|
      v[r.uri] || (r.R.walk pfull,pshort,g,v)} # walk unvisited
    g # graph
  end

  # fetch recursive child-nodes
  def take *a
    node.take(*a).map &:R
  end

  # files describing a resource
  def fileResources
    r = [] # docs
    r.push self if e
    %w{e ht html md n3 ttl txt}.map{|suffix|
      doc = docroot.a '.' + suffix
      r.push doc.setEnv(@r) if doc.e
    }
    r
  end

  FileSet[Resource] = -> e,q,g {
    this = g['']
    e.path.match(/^\/([0-9]{4})\/([0-9]{2})\/([0-9]{2})\/?$/).do{|m| # paginate day-dirs
      t = ::Date.parse "#{m[1]}-#{m[2]}-#{m[3]}" # cast to date
      query = e.env['QUERY_STRING']
      qs = query && !query.empty? && ('?' + query) || ''
      pp = (t-1).strftime('/%Y/%m/%d/') # prev-day
      np = (t+1).strftime('/%Y/%m/%d/') # next-day
      e.env[:Links][:prev] = pp + qs if R['//' + e.env.host + pp].e
      e.env[:Links][:next] = np + qs if R['//' + e.env.host + np].e}
    if e.env[:container]
      cs = e.c # child-nodes
      size = cs.size
      if size < 256
        cs[0].setEnv e.env if cs.size == 1
        e.fileResources.concat cs
      else
        puts "#{e.uri}  #{size} children, paginating"
        FileSet['page'][e,q,g]
      end
    else
      e.fileResources.concat FileSet['rev'][e,q,g]
    end}

  FileSet['find'] = -> e,q,m,x='' {
    e.exist? && q['q'].do{|q|
      r = '-iregex ' + ('.*' + q + '.*' + x).sh
      s = q['size'].do{|s| s.match(/^\d+$/) && '-size +' + s + 'M'} || ""
      t = q['day'].do{|d| d.match(/^\d+$/) && '-ctime -' + d } || ""
      `find #{e.sh} #{t} #{s} #{r} | head -n 255`.lines.map{|l|R.unPOSIX l.chomp}}}

  FileSet['page'] = -> d,r,m {
    c = ((r['c'].do{|c|c.to_i} || 32) + 1).max(1024).min 2 # count
    o = r.has_key?('asc') ? :asc : :desc                   # direction
    (d.take c, o, r['offset'].do{|o|o.R}).do{|s|           # get page
      if r['offset'] && head = s[0] # go backwards
        d.env[:Links][:prev] = d.path + "?set=page&c=#{c-1}&#{o == :asc ? 'de' : 'a'}sc&offset=" + (URI.escape head.uri)
      end
      if edge = s.size >= c && s.pop # another page exists
        d.env[:Links][:next] = d.path + "?set=page&c=#{c-1}&#{o}&offset=" + (URI.escape edge.uri)
      end
      s }}

  FileSet['first-page'] = -> d,r,m {
    FileSet['page'][d,r,m].concat FileSet[Resource][d,r,m]}

  FileSet['rev'] = -> e,req,model {(e.dir.child '.' + e.basename + '*.rev').glob}

  FileSet['localize'] = -> re,q,g {
    FileSet[Resource][re.justPath,q,g].map{|r|
      r.host ? R['/domain/' + r.host + r.hierPart].setEnv(re.env) : r }}

  # https://github.com/groonga/groonga
  # https://github.com/ranguba/rroonga
  ResourceSet['groonga'] = ->d,e,m{
    m['/search'] = {Type => R[Search+'Input']}
    R.groonga.do{|ga|
      q = e['q']                               # search expression
      g = e["context"] || d.env.host # context
      r = (q && !q.empty?) ? ga.select{|r|(r['graph'] == g) & r["content"].match(q)} : # expression if exists
      ga.select{|r| r['graph'] == g}                                                 # or just an ordered set
      start = e['start'].do{|c| c.to_i.max(r.size - 1).min 0 } || 0  # offset
      c = (e['c']||e['count']).do{|c|c.to_i.max(10000).min(0)} || 16 # count
      down = r.size > start+c                                        # prev
      up   = !(start<=0)                                             # next
      r = r.sort(e.has_key?('relevant') ? [["_score"]]:[["time","descending"]],:offset =>start,:limit =>c) # sort
      d.env[:Links][:prev] = '/search/' + {'q' => q, 'start' => start + c, 'c' => c}.qs if down # page pointers
      d.env[:Links][:next] = '/search/' + {'q' => q, 'start' => start - c, 'c' => c}.qs if up
      r.map{|r|
        R[r['.uri']]}}}

  GREP_DIRS.push(/^\/\d{4}\/\d{2}/) # allow grep within a particular month

  FileSet['grep'] = -> e,q,m { # matching files
    e.exist? && q['q'].do{|query|
      GREP_DIRS.find{|p|e.path.match p}.do{|_|
        e.env[:filters].push 'grep'
        `grep -iRl #{query.sh} #{e.sh} | head -n 255`.lines.map{|r|R.unPOSIX r.chomp}}}}

  Filter['grep'] = -> d,e { # matching resources
    w = e.q['q']
    if w && w.size > 1 # query
      e[:grep] = /#{w.scan(/[\w]+/).join '.*'}/i # to regular-expression
      results = {}
      d.map{|u,r| # visit resources
        if r.to_s.match e[:grep] # matching resource
          id = '#' + rand.to_s.h # new "grep-result" resource
          results[id] = r.merge({Type => R['#grep']})
        else
          d.delete u
        end}
      d.merge! results
    end}

  ViewGroup['#grep'] = -> g,e {
    c = {}
    w = e.q['q'].scan(/[\w]+/).map(&:downcase).uniq # words
    w.each_with_index{|w,i|c[w] = i} # enumerated words
    a = /(#{w.join '|'})/i           # highlight-pattern

    [{_: :style, c: c.values.map{|i| # stylesheet
        b = rand(16777216)                # word color
        f = b > 8388608 ? :black : :white # keep contrasty
        ".w#{i} {background-color: #{'#%06x' % b}; color: #{f}}\n"}}, # word-color CSS

     g.map{|u,r| # matching resources
       r.values.flatten.select{|v|v.class==String}.map{|str| # string values
         str.lines.map{|ls|ls.gsub(/<[^>]+>/,'')}}.flatten.  # lines within strings
         grep(e[:grep]).do{|lines|                           # matching lines
         ['<br>',r.R.href,'<br>', # match URI
            lines[0..5].map{|line| # HTML-render of first 6 matching-lines
              line[0..400].gsub(a){|g| # each word-match
                H({_: :span, class: "w w#{c[g.downcase]}", c: g})}}]}}]} # match <span>

  GET['/domain'] = -> e,r {
    r[:container] = true if e.justPath.e
    r.q['set'] = 'localize'
    nil}

  GET['/search'] = -> d,e {
    e.q['set'] = 'groonga'
    nil}

  GET['/today'] = -> e,r {
    [303, r[:Response].update({'Location'=> Time.now.strftime('/%Y/%m/%d/?') + (r['QUERY_STRING']||'')}), []]}

  ViewA[Search+'Input'] = -> r, e {
    {_: :form, action: r.uri, c: {_: :input, name: :q, value: e.q['q'], style: 'font-size:2em'}}}

  ViewGroup[Search+'Input'] = -> d,e {
    [H.js('/js/search',true),
     d.values.map{|i|
       ViewA[Search+'Input'][i,e]}]}

  Facets = -> m,e {
    a = Hash[((e.q['a']||'sioc:ChatChannel').split ',').map{|a|
               [a.expand,{}]}]

    # statistics
    m.map{|s,r| a.map{|p,_|
        r[p].do{|o|
            o.justArray.map{|o|
            a[p][o]=(a[p][o]||0)+1}}}}

    # identifiers
    i = {}
    c = 0
    n = ->o{i[o] ||= 'f'+(c+=1).to_s}
    [(H.css'/css/facets'),(H.js'/js/facets'),
     {class: :sidebar, c: a.map{|f,v|
         {class: :facet, facet: n[f], # predicate
           c: [{class: :predicate, c: f},
               v.sort_by{|k,v|v}.reverse.map{|k,v| # sort by popularity
                 {facet: n.(k.to_s), # predicate-object tuple
                   c: [{_: :span, class: :count, c: v},
                       {_: :span, class: :name, c: (k.respond_to?(:uri) ? k.R.basename : k.to_s)}]}}]}}},
     m.map{|u,r| # each resource
       type = r.types.find{|t|ViewA[t]}
       a.map{|p,_| # each facet
         [n[p], r[p].do{|o| # value
            o.justArray.map{|o|
              n[o.to_s] # identifier
            }}].join ' '
       }.do{|f|
         [f.map{|o| '<div class="' + o + '">' }, # open wrapper
          ViewA[type ? type : BasicResource][r,e], # resource
          (0..f.size-1).map{|c|'</div>'}, "\n",  # close wrapper
         ]}}]}

  # https://github.com/groonga/groonga
  # https://github.com/ranguba/rroonga
  # load groonga DB at URI
  def groonga
    return Groonga::Database.open pathPOSIX if e # exists, return
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

  # load default groonga DB
  def R.groonga
    @groonga ||=
      (begin require 'groonga'
         R['/index/groonga'].groonga
         Groonga["R"]
       rescue LoadError => e
         puts e
       end)
  end
  
  # index resource
  def roonga graph="localhost", m = self.graph
    R.groonga.do{|g|
      m.map{|u,i|
        r = g[u] || g.add(u) # create or load entry
        r.uri = u            # update data
        r.graph = graph.to_s
        r.content = i.to_json
        r.time = i[R::Date].do{|t|t[0].to_time}
      }}
    self
  end
  
  # unindex resource
  def unroonga
    g = R.groonga
    graph.keys.push(uri).map{|u|g[u].delete}
  end

  def triplrUriList
    open(pathPOSIX).readlines.map{|l|
      yield l.chomp, Type, R[Resource] }
  end

  def triplrRevLinks
    pcs = basename('.rev').tail.split '.'
    pMini = pcs.pop
    base = pcs.join '.'
    p = pMini.expand
    o = R[dirname + base]
    triplrUriList do |s,__,_|
      yield s, Type, R[Referer]
      yield s, p, o
    end
  end

  ViewGroup[Referer] = -> g,e {
    [{_: :style,
      c: "
div.referers {
text-align:center;
}
a.referer {
font-size: 2em;
margin:.16em;
color:#fff;
background-color:#{e[:color]};
padding:.16em;
border-radius:.1em;
text-decoration: none;
}
"},
     {class: :referers,
      c: g.keys.map{|uri|
        {_: :a, class: :referer, href: uri, c: '&larr;'}}}]}

end

class Pathname

  def c # children
    return [] unless directory?
    children.delete_if{|n| n.basename.to_s.match /^\./}
    rescue
      []
  end

  # depth-first sorted traverse w/ offset + limit
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
