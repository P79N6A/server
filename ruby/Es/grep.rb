#watch __FILE__
class E

  fn 'set/grep',->e,q,m{
    q['i'] ||= true # normal people want case-insensitive, i think - comment to unstick
    q['q'].do{|query|
      [e,e.pathSegment].compact.select(&:e).map{|e|
        grep = "grep -rl#{q.has_key?('i') && 'i'} #{query.sh} #{e.sh}"  # ;puts grep
        `#{grep}`}.map{|r|r.lines.to_a.map{|r|r.chomp.unpathFs}}.flatten}}

  fn 'view/grep',->d,e{
    w = e.q['q']
    e.q['set']='grep'
    unless w
      F['view/search'][d,e]
    else
      # words supplied in query
      w = w.scan(/[\w]+/).map(&:downcase).uniq

      # word index
      c={}
      w.each_with_index{|w,i|
        c[w] = i }

      # OR pattern
      a = /(#{w.join '|'})/i
      # sequential pattern
      p = /#{w.join '.*'}/i

      [H.css('/css/search'), H.css('/css/grep'),
       F['view/search/form'][e.q,e],
       {_: :style, c: c.values.map{|i|
           # word color
           b = rand(16777216)
           # keep text contrasty
           f = b > 8388608 ? :black : :white

           # word CSS
           ".w#{i} {background-color: #{'#%06x' % b}; color: #{f}}\n"}},

       # each resource
       d.map{|u,r|
         # model to text/plain
         l = F[Render+'text/plain'][{u => r},e].gsub(/<[^>]*>/,'').lines

         # try sequential match
         g = l.grep p
         # try OR match
         g = l.grep a if g.empty?                           

         # match?
         !g.empty? &&                                       
         [# link to resource
          r.E.do{|e|{_: :a, href: e.url, c: e}}, '<br>',
          # show 3 matches per resource
          [g[-1*(g.size.max 3)..-1].map{|l|   
             # exerpt
             l[0..403].gsub(a){|g|
               H({_: :span, class: "w w#{c[g.downcase]}",c: g})}
           },"<br>"]]},
       {_: :a, class: :down, href: e['REQUEST_PATH']+e.q.except('view').qs, style: "background-color: #{E.cs}",c: '&darr;'}]
    end }

end
