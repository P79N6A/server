watch __FILE__
class E

# rapper from http://librdf.org/raptor/

# curl http://prefix.cc/popular/all.file.txt > prefix.txt
# curl http://data.whats-your.name/schema/gromgull.gz | zcat > properties.txt
# wget http://schema.org/docs/schema_org_rdfa.html

  def E.schema
    g = {}
    d = E.schemaDocs
    # fetch/cache/index schemas
    d.map &:schemaCache
    # all schemas to single NTriples file
    d.map(&:ef).flatten.map{|d|d.graphFromFile g}
    puts g.keys.size
  end

  def schemaCache
    weight = E.schemaWeights

    # cache Turtle representation
    ttl.w(`rapper -o turtle #{uri}`) unless ttl.e

    # except indexed docs & huge dbpedia/wordnet dumps
    unless ef.e || ttl.do{|t| t.e && t.size > 256e3}
      g = ttl.graphFromFile
      g.map{|u,r|     # each resource
        if weight[u]
          r['http://schema.whats-your.name/usageFrequency'] = weight[u]
        end }
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
    
  }
  
  fn 'schema/weight',->d,e{
    q = e.q['q']
    d.keys.map{|k| k.class==String && d[k].class==Hash &&
      (s=0
       u=k.downcase
       d[k]['/frequency'][0].to_i.do{|f|f > 0 && (s=s + (Math.log f))}
       s=s+(u.label.match(q.downcase) && 6 || 
            q.camelToke.map(&:downcase).map{|c|
              u.match(c) && 3 || 0}.sum)
       d[k]['score'] = s )}}

end
