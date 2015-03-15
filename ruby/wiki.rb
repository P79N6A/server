# coding: utf-8
#watch __FILE__
class R
 
  FileSet['history'] = -> d,env,g {
    FileSet['page'][d.fragmentDir,env,g].map{|f|f.setEnv env}}

  Render[WikiText] = -> texts {
    texts.justArray.map{|t|
      content = t[Content]
      case t['datatype']
      when 'markdown'
        ::Redcarpet::Markdown.new(::Redcarpet::Render::Pygment, fenced_code_blocks: true).render content
      when 'html'
        StripHTML[content]
      when 'text'
        content.hrefs
      end}}

  ViewGroup[Wiki] = -> g,e {
    [H.css('/css/wiki'),
     g.values.map{|r|
       ViewA[Wiki][r,e]}]}

  ViewA[Wiki] = -> r,e {
    {class: :wiki,
     c: [{_: :a, class: :wikiTitle, href: r.uri, c: r[Title]},
         ([{_: :a, class: :edit, href: r.R.editLink(e), c: R.pencil, title: 'edit Wiki description'},'<br>',
           {_: :a, class: :addArticle, href: r.R.docroot.uri + '?new', c: "+article"}] if e.signedIn), '<br>',
         {_: :span, class: :desc, c: r[Content]}]}}

  ViewGroup[SIOCt+'WikiArticle'] = -> g,e {
    [H.css('/css/wiki'),
     g.map{|u,r|
       ViewA[SIOCt+'WikiArticle'][r,e]}]}

  ViewA[SIOCt+'WikiArticle'] = -> r,e {
    doc = r.R.docroot.uri
    [{_: :a,
      class: :articleTitle,
      href: r.uri, c: r[Title]},
     ([{_: :a, class: :edit, href: r.R.editLink(e), c: R.pencil,
        title: 'edit article description'},
       {_: :a, class: :addSection, href: doc + '?new&type=sioct:WikiArticleSection', c: '+section',
        title: 'add section'}] if e.signedIn),
     '<br>',
     Render[WikiText][r[WikiText]]]}

  ViewGroup[SIOCt+'WikiArticleSection'] = -> g,e {
    g.map{|u,r|
      ViewA[SIOCt+'WikiArticleSection'][r,e]}}

  ViewA[SIOCt+'WikiArticleSection'] = -> r,e {
    {class: :section,
     c: [{_: :a,
          class: :sectionTitle,
          href: r.uri,
          c: r[Title]},
         '<br>',
         Render[WikiText][r[WikiText]],
         ({_: :a,
           href: r.R.docroot +  '?edit&fragment=' + r.R.fragment,
           class: :edit,
           c: '✑'} if e.signedIn)]}}

end
