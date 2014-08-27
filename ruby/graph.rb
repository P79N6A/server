#watch __FILE__
class R

  # a simple alternative to RDF.rb
  # Hash/JSON :: {uri => {property => val}}

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
     (e = u.R                 # resource URI
      doc = e.jsonDoc         # doc URI
      doc.e ||                # cache hit ||
      (docs[doc.uri] ||= {}   # doc graph
       docs[doc.uri][u] = r   # resource -> graph
       p && p.map{|p|         # index predicates
         r[p].do{|v|v.map{|o| # objects exist?
             e.index p,o}}})) if u} # index

    docs.map{|d,g|            # each doc
      d = d.R; puts "<#{d.docroot}>"
      d.w g,true              # cache
      hook[d,g,host] if hook} # write-hook
  end

  # cache JSON docs of resources from triple-stream
  def triplrCacheJSON triplr, host = 'localhost',  p = nil,  hook = nil, &b
    graph = fromStream({},triplr)    # collect triples
    R.cacheJSON graph, host, p, hook # cache
    graph.triples &b if b            # emit triples
    self
  end

  def triplrDoc &f # triples in fs-store at URIs within doc - suitable for serializing to a document (file)
    docroot.glob('#*').map{|s|
      s.triplrResource &f}
  end

  def triplrResource # triples in fs-store at subject URI
    predicates.map{|p|
      self[p].map{|o| yield uri, p.uri, o}}
  end

  def triplrInode dirChildren=true, &f
    if directory?
      d = descend.uri
      yield d, Stat+'size', size
      yield d, Stat+'mtime', mtime.to_i
      [R[Stat+'Directory'], R[LDP+'BasicContainer']].map{|type| yield d, Type, type}
      c.sort.map{|c|c.triplrInode false, &f} if dirChildren

    elsif symlink?
      [R[Stat+'Link'], Resource].map{|type| yield uri, Type, type}
      yield uri, Stat+'mtime', Time.now.to_i
      yield uri, Stat+'size', 0
      readlink.do{|t| yield uri, Stat+'target', t.stripDoc}

    else
      yield stripDoc.uri, Type, Resource
      yield uri, Type, R[Stat+'File']
      yield uri, Stat+'size', size
      yield uri, Stat+'mtime', mtime.to_i
    end
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

  def snapshot
    g = {} # graph
    fromStream g, :triplrDoc
    if g.empty? # 0 triples
      jsonDoc.delete
    else # graph -> doc
      jsonDoc.w g, true
    end
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
