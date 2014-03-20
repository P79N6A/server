#watch __FILE__
class R

  fn 'view/'+Posix+'util#grep',-> d,e {{_: :form, c: [{_: :input, name: :q, style: 'font-size:2em'},{_: :input, type: :hidden, name: :set, value: :grep}]}}

  GREP_DIRS=[]

  fn 'set/grep',->e,q,m{
    q['q'].do{|query| m[e.uri+'#grep'] = {Type => R[Posix+'util#grep']}
      path = e.pathSegment
      GREP_DIRS.find{|p|path.uri.match p}.do{|_|
        [e,path].compact.select(&:e).map{|e|
          `grep -irl #{query.sh} #{e.sh} | head -n 200`}.map{|r|r.lines.to_a.map{|r|r.chomp.unpath}}.flatten
      }}}

  fn 'view/grep',->d,e{
    w = e.q['q']
    if w
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

      [H.css('/css/grep'),
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
          r.R.do{|e|{_: :a, href: e.url, c: e}}, '<br>',
          # show 3 matches per resource
          [g[-1*(g.size.max 3)..-1].map{|l|   
             # exerpt
             l[0..403].gsub(a){|g|
               H({_: :span, class: "w w#{c[g.downcase]}",c: g})}
           },"<br>"]]}]
    end }

end
