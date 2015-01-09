class R

  ViewGroup[SIOC+'Forum'] = -> g,e {
    [H.css('/css/forum'),
     g.values.map{|r|ViewA[SIOC+'Forum'][r,e]}]}

  ViewA[SIOC+'Forum'] = -> r,e {
    re = r.R.stripFrag
    {class: :forum, c: [{_: :h1, c: {_: :a, href: re.uri, c: r[Title]}},
      {_: :a, class: :new, href: re.uri + '?new&type=sioct:BoardPost', c: "+ post on #{re.basename}"}]}}

end
