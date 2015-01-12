watch __FILE__
class R

  ViewGroup[SIOC+'Forum'] = -> g,e {
    [H.css('/css/forum'),
     g.values.map{|r|ViewA[SIOC+'Forum'][r,e]}]}

  ViewA[SIOC+'Forum'] = -> r,e {
    re = r.R.stripFrag
    title = r[Title][0]
    {class: :forum,
     c: [{_: :a, class: :title, href: re.uri.t + '?set=page', c: title},' ',
         {_: :span, class: :desc, c: r[Content]},'<br>',
      {_: :a, class: :new, href: re.uri + '?new&type=sioct:BoardPost', c: "+ post on #{title}"}]}}

  ViewGroup[SIOCt+'BoardPost'] = -> g,e {
    g.values.map{|r|
      r[SIOC+'reply_to'] = R['#']
    }
    ViewGroup[SIOCt+'MailMessage'][g,e]}

end
