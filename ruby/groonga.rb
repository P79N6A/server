#watch __FILE__
class R
=begin
      gem install rroonga
      a ruby full-text searcher & column-store
      http://groonga.org/
=end
  
  fn 'view/'+Search+'Groonga',-> d,e {{_: :form, action: '/', c: [{_: :input, name: :q, style: 'font-size:2em'},{_: :input, type: :hidden, name: :graph, value: :groonga}]}}

  fn 'protograph/groonga',->d,e,m{
    R.groonga.do{|ga|
    q = e['q']                               # search expression
    g = e["context"] || d.env['SERVER_NAME'] # context

    begin
      m['/'] = {Type => R[Search+'Groonga']} # add a groonga resource to the graph

      r = (q && !q.empty?) ? ga.select{|r|(r['graph'] == g) & r["content"].match(q)} : # expression if exists
        ga.select{|r| r['graph'] == g}                                                 # or just an ordered set

      start = e['start'].do{|c| c.to_i.max(r.size - 1).min 0 } || 0  # offset
      c = (e['c']||e['count']).do{|c|c.to_i.max(10000).min(0)} || 16 # count
      down = r.size > start+c                                        # prev
      up   = !(start<=0)                                             # next
      r = r.sort(e.has_key?('best') ? [["_score"]]:[["time","descending"]],:offset =>start,:limit =>c) # sort
      r = r.map{|r|r['.uri'].R}                                      # read URI
      (r.map &:docs).flatten.uniq.map{|r|m[r.uri] = r.env e}         # set resource thunks

      m['#'] = {'uri' => '#', RDFs+'member' => r, Type=>R[HTTP+'Response']} # add pagination data to request-graph
      m['#'][Prev]={'uri' => '/' + {'graph' => 'groonga', 'q' => q, 'start' => start + c, 'c' => c}.qs} if down
      m['#'][Next]={'uri' => '/' + {'graph' => 'groonga', 'q' => q, 'start' => start - c, 'c' => c}.qs} if up

    rescue Groonga::SyntaxError => x
      m['#'] = {Type => R[COGS+'Exception'], Title => "invalid expr", Content => CGI.escapeHTML(x.message)}
    end

    F['docsID'][m,e]}}

  def R.groonga
    @groonga ||=
      (begin require 'groonga'
         R['/index/groonga'].groonga
         Groonga["R"]
       rescue LoadError => e; end)
  end

  # init groongaDB
  def groonga
    return Groonga::Database.open d if e # open db
    dirname.mk                           # create containing dir
    Groonga::Database.create(:path => d) # create db
    Groonga::Schema.define{|s|           # create schema
      s.create_table("R",:type => :hash,:key_type => "ShortText"){|t|
        t.short_text "uri"
        t.short_text "graph"
        t.text "content"
        t.time "time" }
      s.create_table("Bigram",
                     :type => :patricia_trie,
                     :key_normalize => true,
                     :default_tokenizer => "TokenBigram"){|t|
                                  %w{graph content}.map{|c| t.index("R." + c) }}}
  end
  
  # add
  def roonga graph="global", m = self.graph
    R.groonga.do{|g|
      puts "indexing #{uri}"
      m.map{|u,i|
        r = g[u] || g.add(u) # create or load entry
        r.uri = u            # update data
        r.graph = graph.to_s
        r.content = i.to_s
        r.time = i[R::Date].do{|t|t[0].to_time}
      }}
    self
  end
  
  # remove
  def unroonga
    g = R.groonga
    graph.keys.push(uri).map{|u|g[u].delete}
  end

end
