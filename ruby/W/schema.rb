watch __FILE__
class E
  
  # build schema-cache
  def E.schemaCache
    # download RDF from schema URIs to local cache 
    E.schemaCacheDocs

    # index docs and annotate with usage data
    E.schemaIndexDocs
  end

  # gromgull's BTC statistics
  def E.schemaStatistics
    data = '/predicates.2010'.E
    return "curl http://gromgull.net/2010/09/btc2010data/predicates.2010.gz | zcat > predicates.2010" unless data.E
    # occurrence count :: URI -> int
    usage = {}
    data.read.each_line{|e|
      e.match(/(\d+)[^<]+<([^>]+)>/).do{|r|
        usage[r[2]] = r[1].to_i }}
    usage
  end
  
  # prefix -> schema mapping
  def E.schemaDocs
    source = E['http://prefix.cc/popular/all.file.txt']
    mirror = E['http://localhost/css/i/prefix.cc.txt']
    schemae = (mirror.e ? mirror : source).
      read.split("\n").          # each doc
      grep(/^[^#]/).             # skip commented
      map{|t|t.split(/\t/)[1].E} # URI field
    
  end

  # cache schema docs
  def E.schemaCacheDocs
    E.schemaDocs.map{|d|
      d.docBase.a('.ttl').do{|t| t.e || t.w(`rapper -o turtle #{d}`)}}
  end

  # index schema docs
  def E.schemaIndexDocs
    c = E.schemaStatistics
    E.schemaDocs.map{|s| # each schema
      e = s.docBase.a('.e')   #   JSON,   resource
      t = s.docBase.a('.ttl') # turtle,   rapper fetch
     nt = s.docBase.a('.nt')  # ntriples, statistical annotations
      if (nt.e ||                         # skip already-processed docs
          t.do{|d|d.e && d.size > 256e3}) # skip huge dbpedia/wordnet dumps
        puts "already indexed #{s}"
      else
        g = s.graph       # schema graph
        t.deleteNode      # convert Turtle 
        e.w g, true       #  to JSON (for faster loading)
        s.roonga "schema" # index in rroonga
        m = {}   ; puts s # statistics graph 
        g.map{|u,_|       # each resource
          c[u] &&       # do stats exist?
          m[u] = {'uri'=>u, '/frequency' => c[u]}} # add to graph
        nt.w E.renderRDF m # store N-triples
      end
    }
  end
  
  def E.schemaUnindexDocs
    E.schemaDocs.map{|s|
      s.docBase.a('.nt').deleteNode
    }
  end

  # make slash-URIs resolvable
  # E.schemaDocs.map &:schemaLinkSlashURIs
  def schemaLinkSlashURIs
    doc = docBase.a('.e') # document
    return if !doc.e      # cache populated?
    puts "scanning #{uri}"
    graph.do{|m|                     # build graph
      m.map{|u,r|                    # iterate through URIs
        r[RDFs+'isDefinedBy'].do{|d| # check for DefinedBy attribute
          t = u.E.docBase.a '.e'     # symlink location
          t.dirname.dir              # container dir of symlink
          doc.ln t unless t.e        # make link
          puts "#{t} -> #{doc}"
        }}}
    rescue Exception => e
    puts e
  end

  fn '/schema/GET',->e,r{
    r.q.merge!({
                 'graph'=>'roonga',
                 'context'=>'schema',
                 'view'=>'search',
                 'filter'=>'frag',
                 'v'=>'schema',
                 'c'=>(r.q.has_key?('q') ? 1000 : 0)
               })
    e.response
  }
  
  fn 'u/schema/weight',->d,e{
    q = e.q['q']
    d.keys.map{|k| k.class==String && d[k].class==Hash &&
      (s=0
       u=k.downcase
       d[k]['/frequency'][0].to_i.do{|f|f > 0 && (s=s + (Math.log f))}
       s=s+(u.label.match(q.downcase) && 6 || 
            q.camelToke.map(&:downcase).map{|c|
              u.match(c) && 3 || 0}.sum)
       d[k]['score'] = s )}}
  
  fn 'view/schema',->d,e{
    # score resources on popularity, URL friendliness 
    Fn 'u/schema/weight',d,e
    # sort updated response-graph based on score
    d = d.select{|u,r|
      r['score'] && r['score'].respond_to?(:>)
    }.sort_by{|u,r| r['score'] }.reverse

    d.size > 0 &&
    (# fit values to CSS range
     scale = 255 / d[0][1]['score'].do{|s|s > 0 && s || 1}
     [(H.css '/css/schema'),'<table>',
      d.map{|u,r|
        # score -> normalized score
        v = r['score'] * scale
        # score -> greyscale value
        f = '%02x' % v
        # greyscale val -> full CSS
        style = 'color:#'+(v > 128 ? '000' : 'fff')+';background-color:#'+f+f+f
        # stats on stats
        title = r['/frequency'][0].to_s + ' | %.3f'%r['score']

        [{_: :tr, class: :overview, style: style, title: title,
           c: [{_: :td, class: :identity,
                 c: u.E.html},
               {_: :td, class: :label,
                 c: [{_: :span, class: :stats, c: title},
                     r[RDFs+'label'][0].do{|l|
                       {_: :a, href: r.uri,class: :label,c: l}}]}]},
         {_: :tr, class: :details, style: style, title: title,
           c: {_: :td, colspan: 2, class: :describe,
             c: [r[RDFs+'comment'][0].do{|l|
                   {_: :span,class: :comment, c: l}},' ',
                 {_: :a, href: '/@'+u.sub('#','%23')+'?view=tab&filter=p&p=dc:description,rdfs:comment,rdfs:label,rdfs:subPropertyOf,uri',
                   c: '&gt;&gt;'}]}}]},'</table>'])}

end
