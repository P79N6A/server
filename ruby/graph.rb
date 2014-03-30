#watch __FILE__
class R

  fn 'fileset',->e,q,g{
    s = []
    s.concat e.docs
    e.pathSegment.do{|p| s.concat p.docs unless p.uri == '/'}
    e.env['REQUEST_PATH'].match(/(.*?\/)([0-9]{4})\/([0-9]{2})\/([0-9]{2})(.*)/).do{|m| # path a day-dir?
      t = ::Date.parse "#{m[2]}-#{m[3]}-#{m[4]}" # Date object
      pp = m[1] + (t-1).strftime('%Y/%m/%d') + m[5] # prev day
      np = m[1] + (t+1).strftime('%Y/%m/%d') + m[5] # next day
      g['#'][Prev] = {'uri' => pp} if pp.R.e || R['http://' + e.env['SERVER_NAME'] + pp].e
      g['#'][Next] = {'uri' => np} if np.R.e || R['http://' + e.env['SERVER_NAME'] + np].e }
    s }

  def fromStream m,*i
    send(*i) do |s,p,o|
      m[s] = {'uri' => s} unless m[s].class == Hash 
      m[s][p] ||= []
      m[s][p].push o unless m[s][p].class != Array || m[s][p].member?(o)
    end; m
  end

  def graph g={}
    docs.map{|d|d.toGraph g} ;g
  end

  def toGraph g={}
    return unless e
    doc = self
    unless ext=='e' # already native-format
      doc = R '/cache/RDF/' + uri.h.dive
      unless doc.e && doc.m > m # up-to-date?
        graph = {}
        [:triplrInode,:triplrMIME].map{|t| fromStream graph, t}
        doc.w graph, true
      end
    end
    g.mergeGraph doc.r true
  end

  def docs
    [(self if e),
     stripDoc.glob(".{e,jsonld,n3,nt,rdf,ttl}"),
     ((node.directory? && uri[-1]=='/') ? c : []) # trailing slash -> children
    ].flatten.compact
  end

  # GET Resource -> local RDF cache
  # JSON + Hash (.e)
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
      d = d.R; puts "<#{d.stripDoc}>"
      d.w g,true              # write
      hook[d,g,host] if hook} # insert-hook
    graph.triples &b if b     # emit triples
    self
  end

  # GET Resource -> local RDF cache
  # RDF::Repository (.n3)
  def addDocsRDF options = {}
    g = RDF::Repository.load self, options
    g.each_graph.map{|graph|
      if graph.named?
        doc = graph.name.n3
        unless doc.e
          doc.dirname.mk
          RDF::Writer.open(doc.d){|f|f << graph} ; puts "<#{doc.stripDoc}> #{graph.count} triples"
          options[:hook][doc,graph,options[:hostname]] if options[:hook]
        end
      end}
    g
  end

  def jsonDoc; stripDoc.a '.e' end

  def triplrJSON
    yield uri, '/application/json', r(true) if e
  rescue Exception => e
  end

  def to_json *a
    {'uri' => uri}.to_json *a
  end

  fn Render+'application/json',->d,_=nil{d.to_json}

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
