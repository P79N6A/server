#watch __FILE__
class R

  # an alternative to RDF library in Hash/JSON :: {uri => {property => val}}
  # the RDF::Reader for this format is in RDF.rb

  def fromStream m,*i
    send(*i) do |s,p,o|
      m[s] = {'uri' => s} unless m[s].class == Hash 
      m[s][p] ||= []
      m[s][p].push o unless m[s][p].class != Array || m[s][p].member?(o)
    end; m
  end

  def graph graph = {}
    fileResources.map{|d|
      d.fileToGraph graph}
    graph
  end

  def fileToGraph graph = {}
    justRDF(%w{e}).do{|file|
     graph.mergeGraph file.r true}
    graph
  end

  def R.cacheJSON graph, host = 'localhost',  p = nil,  hook = nil
    docs = {} # document bin
    graph.map{|u,r| # each resource
      e = u.R                 # resource URI
      doc = e.jsonDoc         # doc URI
      doc.e ||                # cache hit ||
      (docs[doc.uri] ||= {}   # doc graph
       docs[doc.uri][u] = r   # resource -> graph
       p && p.map{|p|         # index-predicates list
         r[p].do{|v|v.map{|o| # objects exist?
             e.index p,o}}})} # index triples

    docs.map{|d,g|            # each doc
      d = d.R; puts "<#{d.docroot}>"
      d.w g,true              # cache
      hook[d,g,host] if hook} # write-hook
  end

  # cacheJSON as side-effect of a triplr
  def triplrCacheJSON triplr, host = 'localhost',  p = nil,  hook = nil, &b
    graph = fromStream({},triplr)    # collect triples
    R.cacheJSON graph, host, p, hook # cache
    graph.triples &b if b            # emit triples
    self
  end

  def jsonDoc; docroot.a '.e' end

  def triplrJSON
    yield uri, RDFns + 'JSON', r(true) if e
  rescue Exception => e
    puts "triplrJSON #{e}"
  end

  def to_json *a
    {'uri' => uri}.to_json *a
  end

  Render['application/json'] = -> d,e { JSONview[e.q['view']].do{|f|f[d,e]} || d.to_json }

end

class Array
  def except el
    self.- el.justArray
  end
end

class Hash

  def except *ks
    clone.do{|h|
      ks.map{|k|h.delete k}
      h}
  end

  def graph g
    g.merge!({uri=>self})
  end

  def mergeGraph g
    g.triples{|s,p,o|
      self[s] = {'uri' => s} unless self[s].class == Hash 
      self[s][p] ||= []
      self[s][p].push o unless self[s][p].member? o } if g
    self
  end

  def triples &f
    map{|s,r|
      r.map{|p,o|
        o.justArray.map{|o|yield s,p,o} unless p=='uri'} if r.class == Hash}
  end

  def resourcesOfType type
    values.select{|resource|
      resource[R::Type].do{|types|
        types.justArray.map(&:maybeURI).member? type }}
  end

end
