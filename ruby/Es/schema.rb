watch __FILE__
class E
=begin
 www)
 http://data.whats-your.name

 local)
  wget http://whats-your.name/schema.txt
  x-www-browser http://localhost/schema

 manual rebuild of schemacache)
 1) fetch
 ) RDF schema pointer document
   curl http://prefix.cc/popular/all.file.txt > prefix.txt  
 ) RDF usage data
   curl http://data.whats-your.name/schema/gromgull.gz | zcat > properties.txt  
 ) other schemae as RDF
   wget http://schema.org/docs/schema_org_rdfa.html
   ..
 2) analyze
 irb> E.cacheSchemas
  ..  E.indexSchemas

 your schema missing? encourage publishing on WWW and contacting prefix.cc admins
 see also http://www.w3.org/2013/04/vocabs/

=end 

UsageWeight = 'http://schema.whats-your.name/usageFrequency'

  def E.cacheSchemas
    E.schemaDocs.map &:schemaRDF
  end

  def E.indexSchemas
    g = {}
    E.schemaDocs.map(&:ef).flatten.map{|d|d.graphFromFile g}
    '/schema.txt'.E.w g.map{|u,r|
      [(r[UsageWeight]||0),u,r[Label],r[DC+'description'],r[Purl+'dc/elements/1.1/description'],r[RDFs+'comment']].join(' ').gsub("\n"," ") if u.path?
    }.compact.join "\n"
  end

  def schemaRDF
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
    @gromgull ||=
      (data = '/properties.txt'.E
       (puts "download\ncurl http://data.whats-your.name/schema/gromgull.gz | zcat > predicates.txt"; exit) unless data.e
       w = {}
       data.read.each_line{|e|
         e.match(/(\d+)[^<]+<([^>]+)>/).do{|r|
           w[r[2]] = r[1].to_i }}
       w)
  end
  
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
    if (q = r.q['q']) && !q.empty?
      search = "grep -i #{q.sh} #{'/schema.txt'.E.d} | head -n 255"
      found = `#{search}`.to_utf8.lines.to_a.map{|i|
        c,u,t = i.split ' ',3
        c = c.to_i
        [("<b>#{c}</b>" unless c.zero?),
         " <a href='#{u}'>#{F['abbrURI'][u]}</a> ",
         t,"<br>\n"]}
    end
    (H ['<html><body>',(H.css '/css/search'),(H.css '/css/schema'),(H.js '/js/search'),
        F['view/search/form'][r.q,r], found,
        'source ',{_: :a, href: 'http://prefix.cc', c: 'prefix.cc'},' and ',{_: :a, href: 'http://schema.org', c: 'schema.org'},
       ]).hR}
  
end
