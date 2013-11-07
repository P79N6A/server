watch __FILE__
class E
=begin  
  build a local, searchable cache of RDF schemae

  "rapper" from raptor2-utils is used
  and 3rd-party data:

  curl http://prefix.cc/popular/all.file.txt > prefix.txt
  curl http://data.whats-your.name/schema/gromgull.gz | zcat > predicates.txt

=end

  # build schema-cache
  def E.schemaCache
    E.schemaDocs.map &:schemaCache
  end

  def E.schemaUncache
    E.schemaDocs.map &:schemaUncache
  end

  def schemaCache
    weight = E.schemaStatistics

    # cache Turtle representation of resource
    ttl.w(`rapper -o turtle #{uri}`) unless ttl.e

    # skip indexed docs & huge dbpedia/wordnet dumps
    unless nt.e || ttl.do{|t| t.e && t.size > 256e3}
      m={}                # statistics graph 
      graph.map{|u,_|
        weight[u] &&
        m[u] = {'uri'=> u,
          '/frequency' => weight[u]}}
      nt.w E.renderRDF m, :ntriples
      schemaLinkSlashURIs
    end
  end

  def schemaLinkSlashURIs undo=false
    return if !ef.e      # doc exist?
    graph.do{|m|                     # build graph
      m.map{|u,r|                    # iterate through URIs
        r[RDFs+'isDefinedBy'].do{|d| # check for DefinedBy attribute
          t = u.E.ef     # link URI
          t.dirname.mk   # parent dir
          if undo          # undo?
            if t.e         # link exist?
              t.deleteNode # remove link
            end
          else             # do
            unless t.e     # link exist?
              ef.ln t      # add link
            end
          end }}}
  end

  def schemaUnlinkSlashURIs
    schemaLinkSlashURIs :undo
  end

  def schemaUncache
    ef.deleteNode
  end

  # parse gromgull's BTC statistics
  def E.schemaStatistics
    @gromgull ||=
      (data = '/predicates.txt'.E
    (puts "download:\ncurl http://data.whats-your.name/schema/gromgull.gz | zcat > predicates.txt"; exit) unless data.e
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
       mirror = E['/prefix.txt']
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
