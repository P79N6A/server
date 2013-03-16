#watch __FILE__
class E

#  http://groonga.org/ http://ranguba.org/

  def E.groonga
    @groonga ||= (require 'groonga'
                  E['/E/groonga'].groonga
                  Groonga["E"] )
  end

  # schema
  def groonga
    return Groonga::Database.open d if e # exists?
    dirname.dir # create containing path
    Groonga::Database.create(:path => d) # create
    Groonga::Schema.define{|s|
      s.create_table("E",:type => :hash,:key_type => "ShortText"){|t|
        t.short_text "uri" ; t.short_text "graph" ; t.text "content" ; t.time "time" }

      s.create_table("Bigram",:type => :patricia_trie,:key_normalize => true,:default_tokenizer => "TokenBigram"){|t|
        %w{graph content}.map{|c|t.index("E."+c)}}}
  end
  
  # add
  def roonga graph="global", m = memoGraph
    g = E.groonga           # groonga
    r = g[uri] || g.add(uri)# roonga entry
    r.uri = uri          # uri
    r.graph = graph.to_s # graph
    r.content = m.text   # contents
    r.time = m.values[0][E::Date][0].to_time
    self
  end

  def indexFrag c
    graph.map{|u,m|
      u.E.do{|e| e.roonga c, {u => m} }}
  end
  
  # remove
  def unroonga
    E.groonga[uri].delete
  end

  # query
  def E.roonga n, m={} # model
    ga = E.groonga     # engine
    e = n.q            # query string
    q = e['q']         # search
    g = e["graph"] || n['HTTP_HOST']    # graph
    start = e['start'].do{|c|c.to_i}||0 # offset
    c = e['c'].do{|c|c.to_i.max(333).min(0)}||8 # count
    r = q ? ga.select{|r|(r['graph'] == g) & r["content"].match(q)} : # match expression if exists
            ga.select{|r| r['graph'] == g} # an ordered set

    down = r.size > start+c # further results traversible?
    up   = !(start<=0)

    r=r.sort(e.has_key?('score') ? [["_score"]] : [["time", "descending"]],:offset => start,:limit => c) # sort
    m['prev']={'uri' => 'prev','url' => '/search','start' => start + c, 'c' => c} if down # prev set
    m['next']={'uri' => 'next','url' => '/search','start' => start - c, 'c' => c} if up # next set
    r.map{|r|r['.uri'].do{|r|m[r] = r.E.env e}} # create model
    m # model
  end


end
