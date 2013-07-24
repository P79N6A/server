#watch __FILE__
class E

#  http://groonga.org/ http://ranguba.org/

  # default DB
  def E.groonga
    @groonga ||= (require 'groonga'
                  E['/E/groonga'].groonga
                  Groonga["E"] )
  end

  # load or create groongaDB at URI
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
  
  # index resource 
  def roonga graph="global", m = self.graph
    g = E.groonga          # db
    m.map{|u,i|
      r = g[u] || g.add(u) # create or load entry
      r.uri = u            # update data
      r.graph = graph.to_s
      r.content = i.to_s
      r.time = i[E::Date][0].to_time
    }
    self
  end
  
  # remove
  def unroonga
    g = E.groonga
    graph.keys.push(uri).map{|u|g[u].delete}
  end

  # query
  fn 'graph/roonga',->d,e,m{

    # db
    ga = E.groonga

    # search expression
    q = e['q']

    # context
    g = e["context"] || d.env['HTTP_HOST']

    # offset
    start = e['start'].do{|c|c.to_i} || 0

    # number of results
    c = e['c'].do{|c|c.to_i.max(1000).min(0)} || 8

    # exec expression
    r = q ? ga.select{|r|(r['graph'] == g) & r["content"].match(q)} : # expression if exists
            ga.select{|r| r['graph'] == g} # ordered set (index date-range)

    # are further results traversible?
    down = r.size > start+c
    up   = !(start<=0)

    # sort results
    r = r.sort(e.has_key?('score') ? [["_score"]] : [["time", "descending"]],:offset => start,:limit => c)

    # pagination resources
    m['prev']={'uri' => 'prev','url' => '/search','start' => start + c, 'c' => c} if down
    m['next']={'uri' => 'next','url' => '/search','start' => start - c, 'c' => c} if up

    # search-result identifiers
    r = r.map{|r| r['.uri'].E }

    # fragment identifiers
    m['frag'] = {'uri' => 'frag', 'res' => r}

    # containing documents
    r.map(&:docs).flatten.uniq.map{|r| m[r.uri] = r.env e}

    # no 404 on 0 results - searchbox view
    m['/s']={'uri'=>'/s'} if m.empty?

    m # result set
  }
  
end
