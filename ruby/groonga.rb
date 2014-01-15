#watch __FILE__
class E

#  adaptor for ruby text-search-engine & column-store
#  http://groonga.org/ http://ranguba.org/

  # query
  fn 'protograph/roonga',->d,e,m{

    # groonga engine
    ga = E.groonga

    # search expression
    q = e['q']

    # context
    g = e["context"] || d.env['SERVER_NAME']

    begin
      # execute
      r = (q && !q.empty?) ? ga.select{|r|(r['graph'] == g) & r["content"].match(q)} : # expression if exists
        ga.select{|r| r['graph'] == g} # ordered set (index date-range)

      # offset, size
      start = e['start'].do{|c| c.to_i.max(r.size - 1).min 0 } || 0
      c = (e['c']||e['count']).do{|c|c.to_i.max(10000).min(0)} || 8

      # are further results traversible?
      down = r.size > start+c
      up   = !(start<=0)

      # sort results
      r = r.sort(e.has_key?('score') ? [["_score"]] : [["time", "descending"]],:offset => start,:limit => c)

      # results -> graph
      r = r.map{|r| r['.uri'].E }
      (r.map &:docs).flatten.uniq.map{|r| m[r.uri] = r.env e}

      m['#'] = {'uri' => '#',
        RDFs+'member' => r,
        Type=>E[HTTP+'Response']}
      m['#'][Prev]={'uri' => '/search' + {'q' => q, 'start' => start + c, 'c' => c}.qs} if down
      m['#'][Next]={'uri' => '/search' + {'q' => q, 'start' => start - c, 'c' => c}.qs} if up
      m['/search'] = {Type => E[Search]}

    rescue Groonga::SyntaxError => x
      m['/search'] = {Type => E[Search]}
      m['#'] = {
        Type => E[COGS+'Exception'],
        Title => "bad expression",
        Content => CGI.escapeHTML(x.message)}
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
