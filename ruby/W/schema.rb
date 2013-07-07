watch __FILE__
class E
  
  # install schema-cache
  def E.schemaCache
    E.schemaDocs.map &:schemaCache
  end
  def E.schemaUncache
    E.schemaDocs.map &:schemaUncache
  end

  def schemaCache
    schemaCacheDoc
    schemaIndexDoc
  end
  def schemaUncache
    schemaUnindexDoc
    schemaUnlinkSlashURIs
    schemaUncacheDoc
  end

  # cache schema docs
  def schemaCacheDoc
    if ttl.e || ef.e # already cached?
      print "c "
    else
      ttl.w(`rapper -o turtle #{uri}`) # write turtle
    end
  end

  def schemaUncacheDoc
    ef.deleteNode  # remove JSON
    ttl.deleteNode # remove Turtle
  end
  
  # index schema docs
  def schemaIndexDoc
    c = E.schemaStatistics
    if (nt.e ||                           # skip already-processed docs
        ttl.do{|d|d.e && d.size > 256e3}) # skip huge dbpedia/wordnet dumps
      print "e "
    else
      g = graph           # schema graph
      ttl.deleteNode      # convert Turtle 
      ef.w g,true if !ef.e# to JSON (for faster loading)
      roonga "schema"     # index in rroonga
      m={};      puts uri # statistics graph 
      g.map{|u,_|         # each resource
        c[u] &&           # do stats exist?
        m[u] = {'uri'=>u, '/frequency' => c[u]}} # add to graph
      nt.w E.renderRDF m  # store N-triples
      schemaLinkSlashURIs # link "Slash-URI" resources to definer
    end
  end

  def schemaUnindexDoc
    unroonga
    nt.deleteNode
  end

  # make slash-URIs resolvable
  def schemaLinkSlashURIs undo=false
    return if !ef.e      # cache populated?
    graph.do{|m|                     # build graph
      m.map{|u,r|                    # iterate through URIs
        r[RDFs+'isDefinedBy'].do{|d| # check for DefinedBy attribute
          t = u.E.ef     # symlink location
          t.dirname.dir  # container dir of symlink
          if undo
            if t.e
              t.deleteNode # remove link
              puts "-#{t}"
            end
          else
            unless t.e
              ef.ln t      # add link
              puts "#{t} -> #{ef}"
            end
          end
        }}}
    rescue Exception => e
    puts e
  end

  def schemaUnlinkSlashURIs
    schemaLinkSlashURIs :undo
  end

  # parse gromgull's BTC statistics
  def E.schemaStatistics
    @gromgull ||=
      (data = '/predicates.2010'.E
    (puts "curl http://data.whats-your.name/schema/gromgull.gz | zcat > predicates.2010"; exit) unless data.e
    # occurrence count :: URI -> int
    usage = {}
    data.read.each_line{|e|
      e.match(/(\d+)[^<]+<([^>]+)>/).do{|r|
        usage[r[2]] = r[1].to_i }}
    usage)
  end
  
  # parse schema URIs
  def E.schemaDocs
    @docs ||=
      (source = E['http://prefix.cc/popular/all.file.txt']
       mirror = E['http://localhost/css/i/prefix.cc.txt']
       schemae = (mirror.e ? mirror : source).
       read.split("\n").           # each doc
       grep(/^[^#]/).              # skip commented
       map{|t|t.split(/\t/)[1].E}) # URI field
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
                 {_: :a, href: '/@'+u.sub('#','%23')+'?filter=frag',
                   c: '&gt;&gt;'}]}}]},'</table>'])}

end
