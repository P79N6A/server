class R

  # wrap nodes in facet-containers
  Facets = -> m,e { # CSS rules are updated at runtime to control visible-set

    # facetized properties. can be multiple (commma-sep) URI-prefix shortened
    a = Hash[((e.q['a']||'dc:source').split ',').map{|a|
               [a.expand,{}]}]

    # generate statistics
    m.map{|s,r| # resources
      a.map{|p,_| # properties
        r[p].do{|o| # value
            o.justArray.map{|o| # values
              a[p][o] = (a[p][o]||0)+1 # count occurrences
            }}}}

    # filter control
    fid = -> f {
      f = f.respond_to?(:uri) ? f.uri : f.to_s
      f.sub('http','').gsub(/[^a-zA-Z]+/,'_')}
    e[:sidebar].push(a.map{|f,v|
                       {class: :facet, facet: fid[f],
                        c: [{class: :predicate,
                             c: f.shorten.split(':')[-1]},
                            v.sort_by{|k,v|v}.reverse.map{|k,v| # sort by usage-weight
                              name = k.respond_to?(:uri) ? ( k = k.R
                                                             path = k.path
                                                             frag = k.fragment
                                                             if frag
                                                               frag
                                                             elsif !path || path == '/'
                                                               k.host
                                                             else
                                                               path
                                                             end
                                                           ) : k.to_s
                              {facet: fid[k], # facet
                               c: [{_: :span, class: :count, c: v},
                                   {_: :span, name: name, class: :name, # label
                                    c: name}]}}]}}) unless m.keys.size==1

    # HTML
    [(H.css'/css/facets',true),
     (H.js'/js/facets',true),

     # content
     m.resources(e).map{|r| # each resource

       # lookup renderer
       type = r.types.find{|t|ViewA[t]}

       # build facet-identifiers
       a.map{|p,_|
         [fid[p], # p facet
          r[p].do{|o| # p+o facet
            o.justArray.map{|o|fid[o]}}].join ' '
       }.do{|f| # facet-id(s) bound
         [f.map{|o| '<div class="' + o + '">' }, # open wrapper
          ViewA[type ? type : BasicResource][r,e], # resource
          (0..f.size-1).map{|c|'</div>'}, "\n",  # close wrapper
         ]}}]}

  ViewGroup['#grep-result'] = -> g,e {
    c = {}
    w = e.q['q'].scan(/[\w]+/).map(&:downcase).uniq # words
    w.each_with_index{|w,i|c[w] = i} # enumerated words
    a = /(#{w.join '|'})/i           # highlight-pattern

    [{_: :style,
      c: ["h5 a {background-color: #fff;color:#000}\n h5 {margin:.3em}\n",
          c.values.map{|i|
            b = rand(16777216)                # word color
            f = b > 8388608 ? :black : :white # keep contrasty
            ".w#{i} {background-color: #{'#%06x' % b}; color: #{f}}\n"}]}, # word-color CSS

     g.map{|u,r| # matching resources
       r.values.flatten.select{|v|v.class==String}.map{|str| # string values
         str.lines.map{|ls|ls.gsub(/<[^>]+>/,'')}}.flatten.  # lines within strings
         grep(e[:grep]).do{|lines|                           # matching lines
         [{_: :h5, c: r.R.href}, # match URI
            lines[0..5].map{|line| # HTML-render of first 6 matching-lines
              line[0..400].gsub(a){|g|H({_: :span, class: "w w#{c[g.downcase]}", c: g})}}]}}]} # match

  ViewA[Search+'Input'] = -> r, e {
    {_: :form, action: r.uri, c: {_: :input, name: :q, value: e.q['q'], style: 'font-size:2em'}}}

  ViewGroup[Search+'Input'] = -> d,e {
    [H.js('/js/search',true),
     d.values.map{|i|
       ViewA[Search+'Input'][i,e]}]}


end
