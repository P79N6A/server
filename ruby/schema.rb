#watch __FILE__
class E
=begin
 www)  http://data.whats-your.name

 local) cd schema
        curl http://data.whats-your.name/schema/schema.txt.gz | zcat > schema/schema.txt
        x-www-browser http://localhost/schema

 rebuild)
 1) fetch
 ) RDF schema pointer document
   curl http://prefix.cc/popular/all.file.txt > prefix.txt  
 ) RDF usage data
   curl http://data.whats-your.name/schema/gromgull.gz | zcat > properties.txt  
 2) massage
 irb> E.cacheSchemas
  ..  E.indexSchemas

 schema missing? publish and add to prefix.cc,
 see also ideas at http://www.w3.org/2013/04/vocabs/

=end

  UsageWeight = 'http://schema.whats-your.name/usageFrequency'
  SchemasRDFa = %w{http://schema.org/docs/schema_org_rdfa.html}.map &:E

  def E.cacheSchemas
    E.schemaDocs.map &:cacheSchema
    # rapper2 is failing at RDFa autodiscovery, import them again
    SchemasRDFa.map{|s|
      s.ttl.w `rapper -i rdfa -o turtle #{s.uri}`
      s.ef.w s.ttl.graphFromFile,true}
  end

  def E.indexSchemas
    g = {}
    E.schemaDocs.map(&:ef).flatten.map{|d|d.graphFromFile g}
    '/schema/schema.txt'.E.w g.sort_by{|u,r|r[UsageWeight]}.map{|u,r|
      [(r[UsageWeight]||0),
       u,
       r[Label],
       r[DC+'description'],
       r[Purl+'dc/elements/1.1/description'],
       r[RDFs+'comment']
      ].join(' ').gsub("\n"," ") if u.path?
    }.compact.join "\n"
  end

  def cacheSchema
    # write Turtle
    ttl.w(`rapper -o turtle #{uri}`) unless ttl.e

    # except indexed docs & huge dbpedia/wordnet dumps
    unless ef.e || ttl.do{|t| t.e && t.size > 256e3}
      g = ttl.graphFromFile # parse
      g.map{|u,r|           # each resource
        E.schemaWeights[u].do{|w| # grab stats
          r[UsageWeight] = w }}
      ef.w g,true # write annotated graph
    end
  end

  def E.schemaWeights
    @schemaWeights ||=
      (data = '/properties.txt'.E
       (puts "download\ncurl http://data.whats-your.name/schema/gromgull.gz | zcat > predicates.txt"; exit) unless data.e
       w = {}
       data.read.each_line{|e|
         e.match(/(\d+)[^<]+<([^>]+)>/).do{|r|
           w[r[2]] = r[1].to_i }}
       w)
  end
  
  def E.schemaDocs
    @schemaDocs ||=
      (source = E['http://prefix.cc/popular/all.file.txt']
       mirror = E['/prefix.txt']
       (mirror.e ? mirror : source).   # select schema-pointers doc
       read.split(/\n/).grep(/^[^#]/). # each uncommented line
       map{|t| t.split(/\t/)[1].E }.   # parse to resource pointer
       concat SchemasRDFa)             # schema list
  end

  fn '/schema.n3/GET',->e,r{
    g = {}
    if (q = r.q['q']) && !q.empty?
      search = "grep -i #{q.sh} #{'/schema/schema.txt'.E.d} | head -n 86"
      found = `#{search}`.to_utf8.lines.to_a.map{|i|
        c,u,t = i.split ' ',3
        c = c.to_i
        g[u] = {'uri' => u, 'http://www.w3.org/2000/01/rdf-schema#comment' => t, 'http://purl.org/vocommons/voaf#occurrences' => c}}
    end
    [200,{'Content-Type'=>e.env.format+'; charset=utf-8'},[(e.render e.env.format, g, e.env)]]}

  fn '/schema/GET',->e,r{
    q = r.q['q']
    if q && !q.empty?
      search = "grep -i #{q.sh} #{'/schema/schema.txt'.E.d} | head -n 255"
      found = `#{search}`.to_utf8.lines.to_a.map{|i|
        c,u,t = i.split ' ',3
        c = c.to_i
        [("<b>#{c}</b>" unless c.zero?),
         " <a href='#{u}'>#{u.abbrURI}</a> ",
         t,"<br>\n"]}
    end
    (H ['<html><body>',
        q.do{|q|{_: :a, style: 'float:left',href: '/schema.n3?q='+CGI.escape(q), c: {_: :img, src: '/css/misc/cube.png'}}},
        (H.css '/css/search'),(H.css '/css/schema'),(H.js '/js/search'),
        F['view/search/form'][r.q,r], found,
        '<br>sources ',{_: :a, href: 'http://prefix.cc', c: 'prefix.cc'},' and ',{_: :a, href: SchemasRDFa[0], c: 'schema.org'},' ',
       ]).hR}
  
end
