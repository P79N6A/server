watch __FILE__
class E
  F["?"]||={}
  F["?"].update({'du'=>{
                   'graph' => 'du',
                    'view' => 'protovis',
                    'protovis.data' => 'protovis/du',
                    'protovis.view' => 'starburst'
                  }})

  fn 'protograph/du',->d,_,m{
    e = [d,d.pathSegment
        ].find{|f| f.e }
    if e
      puts "du #{e}"
      m[e.uri] = e
    end
    rand.to_s.h
  }

  fn 'graph/du',->e,_,m{
    `du -a #{m.values[0].sh}`.lines.to_a[0..-2].map{|p|
      s,p = p.chomp.split /\t/ # size, path
      p = p.unpathURI    # path -> URI
      m[p.uri]={'uri'=>p.uri,'size'=>s.to_i}}
    m }

  fn 'protovis/du',->e,c{
    m={}        # model
    e.map{|u,r| # each resource
      s = u.sub(/http:..[^\/]+./,'').split '/' # split path
      p = m            # pointer
      s[0..-2].map{|s| # each path segment
        p[s] = {} if !p[s] || p[s].class != Hash # create branch
        p = p[s]}      # advance pointer down tree
      p[s[-1]]||=r['size']} # append size to leaf
    m}

end
