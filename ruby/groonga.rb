watch __FILE__
class R
=begin ruby full-text search & column-store http://groonga.org/
      gem install rroonga
      
=end

  F['/search/GET'] = -> d,e {
    e.q['set'] = 'groonga'
    nil}

  fn 'view/'+Search+'Groonga',-> d,e {
    {_: :form, action: '/search',
      c: {_: :input, name: :q, style: 'font-size:2em'}}}

  fn 'set/groonga',->d,e,m{
    R.groonga.do{|ga|
      q = e['q']                               # search expression
      g = e["context"] || d.env['SERVER_NAME'] # context
      m['/search#'] = {Type => R[Search+'Groonga']} # add a groonga resource to the graph      
      r = (q && !q.empty?) ? ga.select{|r|(r['graph'] == g) & r["content"].match(q)} : # expression if exists
      ga.select{|r| r['graph'] == g}                                                 # or just an ordered set
      start = e['start'].do{|c| c.to_i.max(r.size - 1).min 0 } || 0  # offset
      c = (e['c']||e['count']).do{|c|c.to_i.max(10000).min(0)} || 16 # count
      down = r.size > start+c                                        # prev
      up   = !(start<=0)                                             # next
      r = r.sort(e.has_key?('best') ? [["_score"]]:[["time","descending"]],:offset =>start,:limit =>c) # sort
      r = r.map{|r|r['.uri'].R}                                      # URI field -> Resource
      m['#'][Prev]={'uri' => '/search' + {'q' => q, 'start' => start + c, 'c' => c}.qs} if down
      m['#'][Next]={'uri' => '/search' + {'q' => q, 'start' => start - c, 'c' => c}.qs} if up
      r}}

  def R.groonga
    @groonga ||=
      (begin require 'groonga'
         R['/cache/groonga'].groonga
         Groonga["R"]
       rescue LoadError => e
         puts e
       end)
  end

  # groonga DB at URI
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
  def roonga graph="localhost", m = self.graph
    R.groonga.do{|g|
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
