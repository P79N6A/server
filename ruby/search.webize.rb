class R

  # rewrite URIs to local-cache
  FileSet['localize'] = -> re,q,g {
    FileSet[Resource][re.justPath,q,g].map{|r|
      r.host ? R['/domain/' + r.host + r.hierPart].setEnv(re.env) : r }}

  # serve local resource-cache
  GET['/domain'] = -> e,r {
    r[:container] = true if e.justPath.e
    r.q['set'] = 'localize'
    nil}

  # internal-storage paths, don't serve directly
  GET['/cache'] = E404
  GET['/index'] = E404

  # use "search-result" set
  GET['/search'] = -> d,e {
    e.q['set'] = 'groonga'
    nil}

  # goto today's day-directory
  GET['/today'] = -> e,r {
    [303, r[:Response].update({'Location'=> Time.now.strftime('/%Y/%m/%d/?') + (r['QUERY_STRING']||'')}), []]}

  # summarized contained resources on per-type basis
  Filter[Container] = -> g,e {
    groups = {}
    g.map{|u,r|
      r.types.map{|type| # RDF types
        if v = Abstract[type] # summarizer
          groups[v] ||= {} # type-group
          groups[v][u] = r # resource -> group
        end}}
    groups.map{|fn,gr|fn[g,gr,e]}} # call summarizer(s)

end
