#watch __FILE__
class E

  fn 'set/grep',->e,q,m{
    `grep -rl#{q.has_key?('i') && 'i'} #{q['q'].sh} #{e.sh}`.lines.map &:pathToURI
  }

  fn 'view/grep',->d,e{
    w=e.q['q'].scan(/[\w]+/).map(&:downcase).uniq # split/dedupe words
    c={}; w.each_with_index{|w,i|c[w]=i}                 # word index
    a=/(#{w.join '|'})/i                                  # OR pattern
    p=/#{w.join '.*'}/i                                   # sequential pattern
    [H.css('/css/search'),{_: :style, c: c.values.map{|i| # word styles
       b = rand(16777216)                                 # random color
       f = b > 8388608 ? :black : :white                  # keep text contrasty
       ".w#{i} {background-color: #{'#%06x' % b}; color: #{f}}\n"}},# CSS
     d.map{|u,r| l = r.to_s.gsub(/<[^>]*>/,'').lines      # plaintextify
       g = l.grep p                                       # sequential match first
       g = l.grep a if g.empty?                           # OR match second
       !g.empty? &&                                       # find anything?
       [r.E.do{|e|{_: :a,href: e.url,c: e}},'<br>',       # doc link
        [g[-1*(g.size.max 3)..-1].map{|l|         # show 3 matches per doc
           l[0..404].gsub(a){|g|                   # create exerpt
             H({_: :span, class: "w w#{c[g.downcase]}",c: g})} # style exerpt
         },"<br>"]]}]}

end
