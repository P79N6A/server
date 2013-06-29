#watch __FILE__
class E

#  http://groonga.org/ http://ranguba.org/

  def E.groonga
    @groonga ||= (require 'groonga'
                  E['/E/groonga'].groonga
                  Groonga["E"] )
  end

  # load or create groonga db at URI
  def groonga
    return Groonga::Database.open d if e # open db
    dirname.dir                          # create containing dir
    Groonga::Database.create(:path => d) # create db
    Groonga::Schema.define{|s|           # create schema
      s.create_table("E",:type => :hash,:key_type => "ShortText"){|t|
        t.short_text "uri"
        t.short_text "graph"
        t.text "content"
        t.time "time" }
      s.create_table("Bigram",
                     :type => :patricia_trie,
                     :key_normalize => true,
                     :default_tokenizer => "TokenBigram"){|t|
                                  %w{graph content}.map{|c| t.index("E." + c) }}}
  end
  
  # index
  def roonga graph="global", m = self.graph
    g = E.groonga            # db
    r = g[uri] || g.add(uri) # create or load entry
       r.uri = uri           # update data
     r.graph = graph.to_s
   r.content = m.text
      r.time = m.values[0][E::Date][0].to_time
    self
  end
  
  # remove
  def unroonga
    E.groonga[uri].delete
  end

  # query
  fn 'set/roonga',->d,e,m{

    # load db
    ga = E.groonga

    # search expression
    q = e['q']

    # context
    g = e["context"] || n['HTTP_HOST']

    # offset
    start = e['start'].do{|c|c.to_i} || 0

    # number of results
    c = e['c'].do{|c|c.to_i.max(1000).min(0)} || 8

    r = q ? ga.select{|r|(r['graph'] == g) & r["content"].match(q)} : # expression if exists
            ga.select{|r| r['graph'] == g} # ordered set (index date-range)

    # are further results traversible?
    down = r.size > start+c
    up   = !(start<=0)
    
# E.groonga.select{|r|(r['graph'] == 'schema') & r['content'].match("latitude")}.map{|r|r['.uri']}

    # sort results
    r = r.sort(e.has_key?('score') ? [["_score"]] : [["time", "descending"]],:offset => start,:limit => c)

    # pagination resources
    m['prev']={'uri' => 'prev','url' => '/search','start' => start + c, 'c' => c} if down
    m['next']={'uri' => 'next','url' => '/search','start' => start - c, 'c' => c} if up

    # find containing documents
    r.map{|r|r['.uri'].do{|r|r.E.docs}}.flatten.uniq.map{|r| m[r.uri] = r.env e}

    puts " docs #{m.keys.join ' '}"
    puts " uris #{m.keys.join ' '}"

    m # result set
  }
  
end
