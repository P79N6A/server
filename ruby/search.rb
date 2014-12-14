#watch __FILE__
class R
  GREP_DIRS.push(/^\/\d{4}\/\d{2}/)

  FileSet['find'] = -> e,q,m,x='' {
    e.exist? && q['q'].do{|q|
      r = '-iregex ' + ('.*' + q + '.*' + x).sh
      s = q['size'].do{|s| s.match(/^\d+$/) && '-size +' + s + 'M'} || ""
      t = q['day'].do{|d| d.match(/^\d+$/) && '-ctime -' + d } || ""
      `find #{e.sh} #{t} #{s} #{r} | head -n 255`.lines.map{|l|R.unPOSIX l.chomp}}}

  # depth-first subtree-range in page-chunks
  FileSet['page'] = -> d,r,m {
    u = m['']
    c = ((r['c'].do{|c|c.to_i} || 31) + 1).max(1024).min 2 # count
    o = r.has_key?('asc') ? :asc : :desc                  # direction
    (d.take c, o, r['offset'].do{|o|o.R}).do{|s|          # bind page
      if r['offset'] && head = s[0]
        uri = d.uri + "?set=page&c=#{c-1}&#{o == :asc ? 'de' : 'a'}sc&offset=" + (URI.escape head.uri)
        u[Prev] = {'uri' => uri}                # prev RDF
        d.env[:Links].push "<#{uri}>; rel=prev" # prev HTTP
      end
      if edge = s.size >= c && s.pop            # next exist?
        uri = d.uri + "?set=page&c=#{c-1}&#{o}&offset=" + (URI.escape edge.uri)
        u[Next] = {'uri' => uri}                # next RDF
        d.env[:Links].push "<#{uri}>; rel=next" # next HTTP
      end
      d.env[:Links].push "<#{d.uri+'?set=page&asc'}>; rel=first"
      d.env[:Links].push "<#{d.uri+'?set=page&desc'}>; rel=last"
      s }}

  FileSet['first-page'] = -> d,r,m {
    FileSet['page'][d,r,m].concat FileSet[Resource][d,r,m]}

  FileSet['localize'] = -> re,q,g {
    FileSet[Resource][re.justPath.setEnv(re.env),q,g].map{|r|
      r.host ? R['/domain/' + r.host + r.hierPart].setEnv(re.env) : r }}

  # https://github.com/groonga/groonga
  # https://github.com/ranguba/rroonga
  ResourceSet['groonga'] = ->d,e,m{
    m['/search#'] = {Type => R[Search]}
    R.groonga.do{|ga|
      q = e['q']                               # search expression
      g = e["context"] || d.env['SERVER_NAME'] # context
      r = (q && !q.empty?) ? ga.select{|r|(r['graph'] == g) & r["content"].match(q)} : # expression if exists
      ga.select{|r| r['graph'] == g}                                                 # or just an ordered set
      start = e['start'].do{|c| c.to_i.max(r.size - 1).min 0 } || 0  # offset
      c = (e['c']||e['count']).do{|c|c.to_i.max(10000).min(0)} || 16 # count
      down = r.size > start+c                                        # prev
      up   = !(start<=0)                                             # next
      r = r.sort(e.has_key?('relevant') ? [["_score"]]:[["time","descending"]],:offset =>start,:limit =>c) # sort
      m[''][Prev]={'uri' => '/search/' + {'q' => q, 'start' => start + c, 'c' => c}.qs} if down # pages
      m[''][Next]={'uri' => '/search/' + {'q' => q, 'start' => start - c, 'c' => c}.qs} if up
      r.map{|r|
        R[r['.uri']]}}}

  FileSet['grep'] = -> e,q,m { # matching files
    e.exist? && q['q'].do{|query|
      GREP_DIRS.find{|p|e.path.match p}.do{|_|
        e.env[:Filter] = 'grep'
        `grep -iRl #{query.sh} #{e.sh} | head -n 255`.lines.map{|r|R.unPOSIX r.chomp}}}}

  Filter['grep'] = -> d,e { # matching resources
    w = e.q['q']
    if w && w.size > 1 # query
      e[:grep] = /#{w.scan(/[\w]+/).join '.*'}/i # to regular-expression
      results = {}
      d.map{|u,r| # visit resources
        if r.to_s.match e[:grep]
          id = '#' + rand.to_s.h
          results[id] = r.merge({Type => R['#grepResult']})
        else
          d.delete u
        end}
      d.merge! results
    end}

  ViewGroup['#grepResult'] = -> g,e {
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
    e.ldp
    [303, r[:Response].update({'Location'=> Time.now.strftime('/%Y/%m/%d/?') + (r['QUERY_STRING']||'')}), []]}

  ViewGroup[Search] = -> d,e {
    [{_: :form, action: '/search/', c: {_: :input, name: :q, value: e.q['q'], style: 'font-size:2em'}},
     (H.js '/js/search',true)]}

  def R.trimLines text
    text.lines.map{|l| R.blacklist[l.h] ? "" : l}.join
  end

  def R.blacklist
    @blacklist ||=
      (b = 'index/blacklist.txt'.R
       if b.exist?
         Hash[b.r.lines.map{|l|[l.h,true]}]
       else
         {}
       end)
  end

  Facets = -> m,e {
    a = Hash[((e.q['a']||'sioct:ChatChannel').split ',').map{|a|
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
    [(H.css'/css/facets'),(H.js'/js/facets'),(H.js'/js/mu'),

     # facet selection
     {class: :sidebar, c: a.map{|f,v|
         {class: :facet, facet: n[f], # predicate
           c: [{class: :predicate, c: f},
               v.sort_by{|k,v|v}.reverse.map{|k,v| # sort by popularity
                 {facet: n.(k.to_s), # predicate-object tuple
                   c: [{_: :span, class: :count, c: v},
                       {_: :span, class: :name, c: (k.respond_to?(:uri) ? k.R.abbr : k.to_s)}]}}]}}},

     m.map{|u,r| # each resource
       type = r.types.find{|t|ViewA[t]}
       a.map{|p,_| # each facet
         [n[p], r[p].do{|o| # value
            o.justArray.map{|o|
              n[o.to_s] # identifier
            }}].join ' '
       }.do{|f|
         [f.map{|o| '<div class="' + o + '">' }, # open wrapper
          ViewA[type ? type : Resource][r,e],    # render resource
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

  # index recursive-children
  def reindex graph = host
    visit{|resource|
      puts "index #{resource}"
      resource.roonga graph}
  end

  def q # query-string
    @r.q
  end

end

module Th
  def q # parse query-string
    @q ||=
      (if q = self['QUERY_STRING']
         h = {}
         q.split(/&/).map{|e| k, v = e.split(/=/,2).map{|x| CGI.unescape x }
                              h[k] = v }
         h
       else
         {}
       end)
  end
end

class Hash
  def qs # serialize to query-string
   '?'+map{|k,v|k.to_s+'='+(v ? (CGI.escape [*v][0].to_s) : '')}.intersperse("&").join('')
  end
end
