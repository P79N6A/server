class R

  # grep
  FileSet['grep'] = -> e,q,m { # grep in files
    q['q'].do{|query|
      e.env[:filters].push 'grep'
      `grep -ril #{query.sh} #{e.sh} | head -n 255`.lines.map{|r|
        R.unPOSIX r.chomp}}}

  Filter['grep'] = -> d,e { # grep in-memory graph
    w = e.q['q']
    if w && w.size > 1 # query-str
      e[:grep] = /#{w.scan(/[\w]+/).join '.*'}/i # to regular-expression
      d.map{|u,r| # check resource
        if r.to_s.match e[:grep] # matching resource
          r[Type] ||= []
          r[Type].push R['#grep']
        else
          d.delete u
        end}
    end}

  # groonga  https://github.com/groonga/groonga  https://github.com/ranguba/rroonga
  # gem install rroonga
  ResourceSet['groonga'] = ->d,e,m{
    m['/search'] = {Type => R[Search+'Input']} # add a search-box to response-resources

    R.groonga.do{|ga|
      q = e['q']                     # search expression
      g = e["context"] || d.env.host # context

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
      # resource thunks
      r.map{|r| R[r['.uri']] }}}

  # load DB
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

  # load groonga
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

end
