class E

  fn 'protograph/du',->d,_,m{
    e = [d,d.pathSegment].compact.find &:e
    m[e.uri] = e if e
    rand.to_s.h }

  fn 'graph/du',->e,_,m{
    `du -a #{m.values[0].sh}`.each_line{|l|
      s,p = l.chomp.split /\t/ # size, path
      p = p.unpathFs           # path -> URI
      m[p.uri] = {'uri' => p.uri,
            Stat+'size' => [s.to_i]}}
    m }

end
