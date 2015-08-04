class R

  Facets = -> m,e {
    a = Hash[((e.q['a']||'sioc:ChatChannel').split ',').map{|a|
               [a.expand,{}]}]

    # statistics
    m.map{|s,r| a.map{|p,_|
        r[p].do{|o|
            o.justArray.map{|o|
            a[p][o]=(a[p][o]||0)+1}}}}

    # identifiers
    i = {}
    c = 0
    n = ->o{i[o] ||= 'f'+(c+=1).to_s}
    [(H.css'/css/facets'),(H.js'/js/facets'),
     {class: :sidebar, c: a.map{|f,v|
         {class: :facet, facet: n[f], # predicate
           c: [{class: :predicate, c: f},
               v.sort_by{|k,v|v}.reverse.map{|k,v| # sort by popularity
                 {facet: n.(k.to_s), # predicate-object tuple
                   c: [{_: :span, class: :count, c: v},
                       {_: :span, class: :name, c: (k.respond_to?(:uri) ? k.R.basename : k.to_s)}]}}]}}},
     m.map{|u,r| # each resource
       type = r.types.find{|t|ViewA[t]}
       a.map{|p,_| # each facet
         [n[p], r[p].do{|o| # value
            o.justArray.map{|o|
              n[o.to_s] # identifier
            }}].join ' '
       }.do{|f|
         [f.map{|o| '<div class="' + o + '">' }, # open wrapper
          ViewA[type ? type : BasicResource][r,e], # resource
          (0..f.size-1).map{|c|'</div>'}, "\n",  # close wrapper
         ]}}]}

  ViewGroup['#grep'] = -> g,e {
    c = {}
    w = e.q['q'].scan(/[\w]+/).map(&:downcase).uniq # words
    w.each_with_index{|w,i|c[w] = i} # enumerated words
    a = /(#{w.join '|'})/i           # highlight-pattern

    [{_: :style, c: c.values.map{|i| # stylesheet
        b = rand(16777216)                # word color
        f = b > 8388608 ? :black : :white # keep contrasty
        ".w#{i} {background-color: #{'#%06x' % b}; color: #{f}}\n"}}, # word-color CSS

     g.map{|u,r| # matching resources
       r.values.flatten.select{|v|v.class==String}.map{|str| # string values
         str.lines.map{|ls|ls.gsub(/<[^>]+>/,'')}}.flatten.  # lines within strings
         grep(e[:grep]).do{|lines|                           # matching lines
         ['<br>',r.R.href,'<br>', # match URI
            lines[0..5].map{|line| # HTML-render of first 6 matching-lines
              line[0..400].gsub(a){|g| # each word-match
                H({_: :span, class: "w w#{c[g.downcase]}", c: g})}}]}}]} # match <span>

  ViewGroup[Referer] = -> g,e {
    [{_: :style,
      c: "
div.referers {
text-align:center;
}
a.referer {
font-size: 1.2em;
margin:.16em;
text-decoration: none;
}
"},
     {class: :referers,
      c: g.keys.map{|uri|
        {_: :a, class: :referer, href: uri, c: '&larr;'}}}]}

  ViewA[Search+'Input'] = -> r, e {
    {_: :form, action: r.uri, c: {_: :input, name: :q, value: e.q['q'], style: 'font-size:2em'}}}

  ViewGroup[Search+'Input'] = -> d,e {
    [H.js('/js/search',true),
     d.values.map{|i|
       ViewA[Search+'Input'][i,e]}]}


end
