#watch __FILE__
class E
=begin
      gem install rroonga
      a ruby full-text searcher & column-store
      http://groonga.org/
=end
  
  fn 'view/'+Search+'Groonga',-> d,e {{_: :form, action: '/', c: [{_: :input, name: :q, style: 'font-size:2em'},{_: :input, type: :hidden, name: :graph, val: :groonga}]}}

  fn 'protograph/groonga',->d,e,m{
    ga = E.groonga
    q = e['q']                               # search expression
    g = e["context"] || d.env['SERVER_NAME'] # context

    begin
      r = (q && !q.empty?) ? ga.select{|r|(r['graph'] == g) & r["content"].match(q)} : # expression if exists
        ga.select{|r| r['graph'] == g}                                                 # or just an ordered set

      start = e['start'].do{|c| c.to_i.max(r.size - 1).min 0 } || 0 # offset
      c = (e['c']||e['count']).do{|c|c.to_i.max(10000).min(0)} || 8 # count
      down = r.size > start+c                                       # prev
      up   = !(start<=0)                                            # next
      r = r.sort(e.has_key?('best') ? [["_score"]]:[["time","descending"]],:offset =>start,:limit =>c) # sort
      r = r.map{|r| r['.uri'].E }                                   # URI
      (r.map &:docs).flatten.uniq.map{|r|m[r.uri] = r.env e}        # set resource thunks

      m['#'] = {'uri' => '#', RDFs+'member' => r, Type=>E[HTTP+'Response']} # add pagination data to request-graph
      m['#'][Prev]={'uri' => '/' + {'graph' => 'groonga', 'q' => q, 'start' => start + c, 'c' => c}.qs} if down
      m['#'][Next]={'uri' => '/' + {'graph' => 'groonga', 'q' => q, 'start' => start - c, 'c' => c}.qs} if up
      m['/'] = {Type => E[Search+'Groonga']}

    rescue Groonga::SyntaxError => x
      m['/'] = {Type => E[Search+'Groonga']}
      m['#'] = {Type => E[COGS+'Exception'], Title => "invalid expr", Content => CGI.escapeHTML(x.message)}
      e['nocache']=true
    end

    F['docsID'][m,e]}

  def E.groonga
    @groonga ||= (require 'groonga'
                  E['/E/groonga'].groonga
                  Groonga["E"] )
  end

  # load or create groongaDB at URI
  def groonga
    return Groonga::Database.open d if e # open db
    dirname.mk                           # create containing dir
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
#    puts "text #{graph} < #{uri} #{m.keys.join ' '}"
    g = E.groonga          # db
    m.map{|u,i|
      r = g[u] || g.add(u) # create or load entry
      r.uri = u            # update data
      r.graph = graph.to_s
      r.content = i.to_s
      r.time = i[E::Date].do{|t|t[0].to_time}
    }
    self
  end
  
  # remove
  def unroonga
    g = E.groonga
    graph.keys.push(uri).map{|u|g[u].delete}
  end

end
