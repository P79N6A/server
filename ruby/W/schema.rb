watch __FILE__
class E
  
  def E.cacheSchemas; c = {}    
    puts "parsing gromgull's data"
    '/predicates.2010'.E.read.each_line{|e| # usage data http://gromgull.net/2010/09/btc2010data/predicates.2010.gz
      print "%d%% " % (c.size / 953.0) if c.size % 10000 == 0 # info
      e.match(/(\d+)[^<]+<([^>]+)>/).       # occurrence count
      do{|r| c[r[2]] = r[1].to_i }}         # to hash-table
      puts "\n#{c.size} properties"
    'http://localhost/css/i/prefix.cc.txt'.E. # schema list
      read.split("\n").grep(/^[^#]/).map{|c|  # uncommented lines
      c.split(/\t/).do{|f| Hash['uri', f[1],  # parse prefix table
                              'prefix',f[0]]}}.
      map{|b| b.E.cacheTurtle.           # cache schema locally
              ln "/prefix/"+b['prefix']} # prefix shortcut
    s = E['/prefix/*'].glob      # docs
    s.map{|s| s.size < 2e5 &&    # each schema
      (s.indexFrag 'schema'      # index document
       s.readlink.linkDefined)}  # link slash-URIs to defining doc
      s.map{|r|m = {}; r.graph.map{|u,_|          # each predicate in schema
       c[u] && m[u]={'uri'=>u,'/frequency'=>c[u]}}# annotate with frequency
        r.appendNT m unless m.empty?}             # store in NTriples file
    end
    
    fn '/schema/GET',->e,r{
      [303,
       {'Location'=>'/search' + {
           graph: :schema, m: :graphFrag, view: :search, sort: :score, reverse: :true, v: :schema, c: 1e4
         }.qs},[]]}
    
    fn 'u/schema/weight',->d,e{
      q = e.q['q']
      d.keys.map{|k| k.class==String && d[k].class==Hash &&
        (s=0
         u=k.downcase
         d[k]['/frequency'][0].to_i.do{|f|f > 0 && (s=s + (Math.log f))}
         s=s+(u.label.match(q.downcase) && 12 || 
              q.camelToke.map(&:downcase).map{|c|
                u.match(c) && 6 || 0}.sum)
         d[k]['score'] = s )}}
    
    fn 'view/schema',->d,e{
      Fn 'u/schema/weight',d,e
      d=d.select{|u,r|r['score'] && r['score'].respond_to?(:>)}.
      sort_by{|u,r|r['score']}.reverse
      d.size > 0 &&
      (scale = 255 / d[0][1]['score'].do{|s|s > 0 && s || 1}
       [(H.css '/css/schema'),
        d.map{|u,r|
          v = r['score'] * scale
          f = '%02x' % v
          {class: :r, title: '%.3f'%r['score'],
            style: 'color:#'+(v > 128 ? '000' : 'fff')+';background-color:#'+f+f+f,
            c:[r[RDFs+'label'][0].do{|l|{_: :a, href: r.uri,class: :label,c: l}},
               {_: :a, class: :uri, href: r.uri, c: r.uri[7..-1]},'<br>',
               r[RDFs+'comment'][0].do{|l|{_: :span,class: :comment, c: l}}]}}])}

    def linkDefined
      cacheGraph.do{|m|
        m.map{|u,r|
          r[RDFs+'isDefinedBy'].do{|d|
            prop = (u[-1]=='/' ? u[0..-2] : u).E
            prop.dirname.dir;  puts "d #{prop.dirname} #{prop}"
            ln prop }}}
    end

  end
