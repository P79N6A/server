#watch __FILE__
class R

  FileSet['grep'] = -> e,q,m {
    q['q'].do{|query|
      q['view'] ||= 'grep'
      path = e.justPath
      GREP_DIRS.find{|p|path.uri.match p}.do{|_|
        [e,path].compact.select(&:e).map{|e|
          `grep -irl #{query.sh} #{e.sh} | head -n 200`}.map{|r|r.lines.to_a.map{|r|R.unPOSIX r.chomp}}.flatten
      }}}

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
      m['#'][Prev]={'uri' => '/search' + {'q' => q, 'start' => start + c, 'c' => c}.qs} if down # pages
      m['#'][Next]={'uri' => '/search' + {'q' => q, 'start' => start - c, 'c' => c}.qs} if up
      r.map{|r|r['.uri'].R}}} # URI -> Resource

  View['grep'] = -> d,e {
    w = e.q['q']
    if w && w.size > 1
      # words supplied in query
      w = w.scan(/[\w]+/).map(&:downcase).uniq

      # word index
      c={}
      w.each_with_index{|w,i|
        c[w] = i }

      # OR pattern
      a = /(#{w.join '|'})/i
      # sequential pattern
      p = /#{w.join '.*'}/i

      [{_: :style, c: c.values.map{|i|
           # word color
           b = rand(16777216)
           # keep text contrasty
           f = b > 8388608 ? :black : :white

           # word CSS
           ".w#{i} {background-color: #{'#%06x' % b}; color: #{f}}\n"}},

       # each resource
       d.map{|u,r|

         l = r.values.flatten.select{|v|v.class==String}.map{|s|s.lines.to_a.map{|l|l.gsub(/<[^>]+>/,'')}}.flatten

         # try sequential match
         g = l.grep p
         # try OR match
         g = l.grep a if g.empty?                           

         # match?
         !g.empty? &&                                       
         [# link to resource
          r.R.do{|e|{_: :a, href: e.url, c: e}}, '<br>',
          # max matches per resource
          [g[-1*(g.size.max 6)..-1].map{|l|   
             # exerpt
             l[0..403].gsub(a){|g|
               H({_: :span, class: "w w#{c[g.downcase]}",c: g})}
           },"<br>"]]}]
    end }

  GET['/search'] = -> d,e {
    e.q['set'] = 'groonga'
    e.q.delete 'view' if e.q['view'] == 'ls'
    nil}

  View[Search] = -> d,e {
    [{_: :form, action: '/search', c: {_: :input, name: :q, style: 'font-size:2em'}},
     (H.js '/js/search')]}

  def R.groonga
    @groonga ||= # gem install rroonga
      (begin require 'groonga'
         R['/cache/groonga'].groonga
         Groonga["R"]
       rescue LoadError => e
         puts e
       end)
  end

  # URI -> groonga DB
  def groonga
    return Groonga::Database.open d if e # open db
    dir.mk                               # create containing dir
    Groonga::Database.create(:path => d) # create db
    Groonga::Schema.define{|s|           # create schema
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
  
  # add
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
  
  # remove
  def unroonga
    g = R.groonga
    graph.keys.push(uri).map{|u|g[u].delete}
  end

end
