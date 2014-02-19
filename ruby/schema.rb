#watch __FILE__
class R
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
 irb> R.cacheSchemas
  ..  R.indexSchemas

 schema missing? publish and add to prefix.cc,
 see also ideas at http://www.w3.org/2013/04/vocabs/

=end

  UsageWeight = 'http://schema.whats-your.name/usageFrequency'
  SchemasRDFa = %w{http://schema.org/docs/schema_org_rdfa.html}.map &:R

  def R.cacheSchemas
    R.schemaDocs.map &:cacheSchema
    # rapper2 is failing at RDFa autodiscovery, import them again
    SchemasRDFa.map{|s|
      s.ttl.w `rapper -i rdfa -o turtle #{s.uri}`
      s.ef.w s.ttl.graphFromFile,true}
  end

  def R.indexSchemas
    g = {}
    R.schemaDocs.map(&:ef).flatten.map{|d|d.graphFromFile g}
    '/schema/schema.txt'.R.w g.sort_by{|u,r|r[UsageWeight]}.map{|u,r|
      [(r[UsageWeight]||0),
       u,
       r[Label],
       r[DC+'description'],
       r[Purl+'dc/elements/1.1/description'],
       r[RDFs+'comment']
      ].join(' ').gsub("\n"," ")
    }.compact.join "\n"
  end

  def cacheSchema
    # write Turtle
    ttl.w(`rapper -o turtle #{uri}`) unless ttl.e

    # except indexed docs & huge dbpedia/wordnet dumps
    unless ef.e || ttl.do{|t| t.e && t.size > 256e3}
      g = ttl.graphFromFile # parse
      g.map{|u,r|           # each resource
        R.schemaWeights[u].do{|w| # grab stats
          r[UsageWeight] = w }}
      ef.w g,true # write annotated graph
    end
  end

  def R.schemaWeights
    @schemaWeights ||=
      (data = '/properties.txt'.R
       (puts "download\ncurl http://data.whats-your.name/schema/gromgull.gz | zcat > predicates.txt"; exit) unless data.e
       w = {}
       data.read.each_line{|e|
         e.match(/(\d+)[^<]+<([^>]+)>/).do{|r|
           w[r[2]] = r[1].to_i }}
       w)
  end
  
  def R.schemaDocs
    @schemaDocs ||=
      (open('http://prefix.cc/popular/all.file.txt'). # schemae
       read.split(/\n/).grep(/^[^#]/). # each uncommented line
       map{|t| t.split(/\t/)[1].R }.   # into a Resource
       concat SchemasRDFa)             # schema list
  end

  fn '/schema.n3/GET',->e,r{
    r.q['view']='table'
    g = {}
    if (q = r.q['q']) && !q.empty?
      search = "grep -i #{q.sh} #{'/schema/schema.txt'.R.d} | head -n 255"
      found = `#{search}`.to_utf8.lines.to_a.map{|i|
        c,u,t = i.split ' ',3
        c = c.to_i
        g[u] = {'uri' => u, 'http://www.w3.org/2000/01/rdf-schema#comment' => t, 'http://purl.org/vocommons/voaf#occurrences' => c}}
    end
    [200,{'Content-Type'=>e.env.format+'; charset=utf-8'},[(e.render e.env.format, g, e.env)]]}
  F['/schema/GET']=F['/schema.n3/GET']
  
end
