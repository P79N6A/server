class R

  # rewrite resource-URIs to our local-cache mapping
  FileSet['localize'] = -> re,q,g {
    FileSet[Resource][re.justPath,q,g].map{|r|
      r.host ? R['/domain/' + r.host + r.hierPart].setEnv(re.env) : r }}

  GET['/cache'] = E404
  GET['/index'] = E404

  GET['/domain'] = -> e,r {
    r[:container] = true if e.justPath.e
    r.q['set'] = 'localize'
    nil}

  GET['/search'] = -> d,e {
    e.q['set'] = 'groonga'
    nil}

  GET['/today'] = -> e,r {
    [303, r[:Response].update({'Location'=> Time.now.strftime('/%Y/%m/%d/?') + (r['QUERY_STRING']||'')}), []]}

end
