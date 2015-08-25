class R

  # wrap nodes in facet-containers
  Facets = -> m,e { # CSS rules are updated at runtime to control visible-set

    # facetized properties. can be multiple commma-sep and URI-prefix shortened
    a = Hash[((e.q['a']||'dc:source').split ',').map{|a|
               [a.expand,{}]}]

    # generate statistics
    m.map{|s,r| # resources
      a.map{|p,_| # properties
        r[p].do{|o| # value
            o.justArray.map{|o| # values
              a[p][o] = (a[p][o]||0)+1 # count occurrences
            }}}}

    # facet shortnames
    i = {}
    c = 0
    n = ->o{i[o] ||= 'f'+(c+=1).to_s} # mint an id

    # HTML
    [(H.css'/css/facets',true),
     (H.js'/js/facets',true),

     # filter-rules sidebar
     ({class: :sidebar, c: a.map{|f,v|
         {class: :facet, facet: n[f], # predicate
           c: [{class: :predicate, c: f.shorten.split(':')[-1]},
               v.sort_by{|k,v|v}.reverse.map{|k,v| # sort by popularity
                 {facet: n.(k.to_s), # predicate-object tuple
                   c: [{_: :span, class: :count, c: v},
                       {_: :span, class: :name,
                        c: (k.respond_to?(:uri) ? ( k = k.R
                                                    path = k.path
                                                    frag = k.fragment
                                                    if frag
                                                      frag
                                                    elsif !path || path == '/'
                                                      k.host
                                                    else
                                                      path
                                                    end
                                                  ) : k.to_s)}
                      ]}}]}}} unless m.keys.size==1),
     # content
     m.map{|u,r| # each resource

       # find typed-renderer
       type = r.types.find{|t|ViewA[t]}

       a.map{|p,_| # each facet
         [n[p], r[p].do{|o| # each value
            o.justArray.map{|o|
              n[o.to_s] # find facet-identifier
            }}].join ' '
       }.do{|f| # facet-id bound
         [f.map{|o| '<div class="' + o + '">' }, # open node wrapper(s)
          ViewA[type ? type : BasicResource][r,e], # contained-resource
          (0..f.size-1).map{|c|'</div>'}, "\n",  # close wrappers
         ]}}]}

  # grep the graph and highlight results
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
