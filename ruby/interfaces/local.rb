class R

  def readFile; File.open(pathPOSIX).read end
  def writeFile o; dir.mkdir; File.open(pathPOSIX,'w'){|f|f << o}; self end

  # file(s) -> graph-tree
  def load set
    graph = RDF::Graph.new # graph
    g = {}                 # tree
    rdf,nonRDF = set.partition &:isRDF #partition on file type
    # load RDF
    rdf.map{|n|graph.load n.pathPOSIX, :base_uri => n}
    graph.each_triple{|s,p,o| # each triple
      s = s.to_s; p = p.to_s # subject, predicate
      o = [RDF::Node, RDF::URI, R].member?(o.class) ? o.R : o.value # object
      g[s] ||= {'uri'=>s} # new resource
      g[s][p] ||= []
      g[s][p].push o unless g[s][p].member? o} # RDF to tree
    # load nonRDF
    nonRDF.map{|n|
      n.transcode.do{|transcode| # transcode to RDF
        JSON.parse(transcode.readFile).map{|s,re| # subject
          re.map{|p,o| # predicate, objects
            o.justArray.map{|o| # object
              o = o.R if o.class==Hash
              g[s] ||= {'uri'=>s} # new resource
              g[s][p] ||= []; g[s][p].push o unless g[s][p].member? o} unless p == 'uri' }}}} # RDF to tree
    if q.has_key?('du') && path != '/' # DU usage-count
      set.select{|d|d.node.directory?}.-([self]).map{|node|
        g[node.path+'/']||={}
        g[node.path+'/'][Size] = node.du}
    elsif (q.has_key?('f')||q.has_key?('q')||env[:glob]) && path!='/' # FIND/GREP counts
      set.map{|r|
        bin = r.dirname + '/'
        g[bin] ||= {'uri' => bin, Type => Container}
        g[bin][Size] = 0 if !g[bin][Size] || g[bin][Size].class==Array
        g[bin][Size] += 1}
    end
    g
  end

  # file(s) -> RDF::Graph
  def loadRDF set
    g = RDF::Graph.new; set.map{|n|g.load n.toRDF.pathPOSIX, :base_uri => n.stripDoc}
    g
  end

  # file -> RDF-file
  def toRDF; isRDF ? self : transcode end

  # nonRDF-file -> RDF-file
  def transcode
    return self if ext == 'e'
    hash = node.stat.ino.to_s.sha2
    doc = R['/.cache/'+hash[0..2]+'/'+hash[3..-1]+'.e'].setEnv @r
    unless doc.e && doc.m > m
      tree = {}
      triplr = Triplr[mime]
      unless triplr
        puts "WARNING missing #{mime} triplr for #{uri}"
        triplr = :triplrFile
      end
      send(*triplr){|s,p,o|
        tree[s] ||= {'uri' => s}
        tree[s][p] ||= []
        tree[s][p].push o}
      doc.writeFile tree.to_json
    end
    doc
  rescue Exception => e
    puts uri, e.class, e.message
  end

  # pattern -> file(s)
  def grep q
    args = q.shellsplit
    case args.size
    when 0
      return []
    when 2
      cmd = "grep -rilZ #{args[0].sh} #{sh} | xargs -0 grep -il #{args[1].sh}"
    when 3
      cmd = "grep -rilZ #{args[0].sh} #{sh} | xargs -0 grep -ilZ #{args[1].sh} | xargs -0 grep -il #{args[2].sh}"
    when 4
      cmd = "grep -rilZ #{args[0].sh} #{sh} | xargs -0 grep -ilZ #{args[1].sh} | xargs -0 grep -ilZ #{args[2].sh} | xargs -0 grep -il #{args[3].sh}"
    else
      pattern = args.join '.*'
      cmd = "grep -ril #{pattern.sh} #{sh}"
    end
    `#{cmd} | head -n 1024`.lines.map{|pathName| R.fromPOSIX pathName.chomp}
  end

  def indexMail
    @verbose = true
    triples = 0
    triplrMail{|s,p,o|triples += 1}
    puts "    #{triples} triples"
  rescue Exception => e
    puts uri, e.class, e.message
  end

  def indexMails; glob.map &:indexMail end

end