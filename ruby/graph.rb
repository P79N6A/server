#watch __FILE__
class E

  # Graph -> tripleStream -> Graph
  def fromStream m,*i
    send(*i) do |s,p,o|
      m[s] = {'uri' => s} unless m[s].class == Hash 
      m[s][p] ||= []
      m[s][p].push o unless m[s][p].member? o
    end; m
  end

=begin
 * stream triples into graph (memory)
 * import missing resources to store (fs)
 * behave as normal triplr to caller, with
   side-effect of import/indexing to knowledgebase
=end
  def insertDocs triplr, h=nil, p=[], &b
    graph = fromStream({},triplr)
    graph.map{|u,r| # stream -> graph
      e = u.E           # resource
      j = e.ef          # doc
      j.e ||            # exists?
      (j.w({u=>r},true) ;puts '< '+u # insert doc
       p.map{|p|        # each indexable property
     r[p].do{|v|        # values exists?
       v.map{|o|        # each value
        e.index p,o}}}  # property index 
      e.roonga h if h)} # full-text index
    graph.triples &b if b # emit the triples
    self
  end

  def graphFromFile g={}, triplr=:triplrMIME
    _ = self
    unless ext=='e' # native graph-format already
      # construct native graph if missing or stale
      _ = E '/E/graph/' + uri.h.dive
      unless _.e && _.m > m;  e = {}
        puts "< #{uri}"
        [:triplrInode, triplr].each{|t| fromStream e, t }
        _.w e, true
      end
    end
    g.mergeGraph _.r true
  end

  def graph g={}
    docs.map{|d|d.graphFromFile g}  # tripleStream -> graph
    g
  end

end
