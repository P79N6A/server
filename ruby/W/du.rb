#watch __FILE__
class E

  F["?"]||={}
  F["?"].update({'du'=>{
                   'graph' => 'du',
                    'view' => 'protovis',
                    'protovis.data' => 'protovis/du',
                    'protovis.view' => 'starburst'
                  }})

  fn 'graph/du',->e,_,m{
    `du -a #{e.sh}`.lines.to_a[0..-2].map{|p|
      begin
        s,p=p.split /\t/ # size, path
        p=p[BaseLen..-1].unpath # path -> URI
        m[p.uri]={'uri'=>p.uri,'fs:size'=>s.to_i}
      rescue
        nil
      end
    }
    m}

  fn 'protovis/du',->e,c{
    m={}        # model
    e.map{|u,r| # each resource
      s = u.sub(/http:..[^\/]+./,'').split '/' # split path
      p = m            # pointer
      s[0..-2].map{|s| # each path segment
        p[s] = {} if !p[s] || p[s].class != Hash # create branch
        p = p[s]}      # advance pointer down tree
      p[s[-1]]||=r['fs:size']} # append size to leaf
    m}

end
