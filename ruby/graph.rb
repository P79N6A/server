#watch __FILE__
class R

  # graph in memory as Hash and storage as JSON :: {uri => {property => val}}
  # designed to minimize non-stdlib dependencies + indirection, and speed (C/native JSON-parse vs Ruby RDF-parse for large-requests). arbitrary JSON is roundtripped in the "object" position (of a triple) but no particular literal-datatype/language format is specified.
  # a Reader is defined of this format for the RDF Class

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

  # pass-thru triplr w/ side-effect of add missing resources to store
  def addDocsJSON triplr, host, p=nil, hook=nil, &b
    graph = fromStream({},triplr)
    docs = {}
    graph.map{|u,r|
      e = u.R                 # resource
      doc = e.jsonDoc         # doc
      doc.e ||                # exists - we're nondestructive here
      (docs[doc.uri] ||= {}   # init doc-graph
       docs[doc.uri][u] = r   # add to graph
       p && p.map{|p|         # index predicate
         r[p].do{|v|v.map{|o| # values exist?
             e.index p,o}}})} # index triple
    docs.map{|d,g|            # resources in docs
      d = d.R; puts "<#{d.docroot}>"
      d.w g,true              # write
      hook[d,g,host] if hook} # insert-hook
    graph.triples &b if b     # emit triples
    self
  end

  def jsonDoc; docroot.a '.e' end

  def triplrJSON
    yield uri, '/application/json', r(true) if e
  rescue Exception => e
    puts "triplrJSON #{e}"
  end

  def to_json *a
    {'uri' => uri}.to_json *a
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
