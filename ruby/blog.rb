#watch __FILE__
class R

  # paginated blog-posts
  # mountable on site-root, GET['host/'] = GET['/blog']
  GET['/blog'] = -> d,e {
    if %w{/ /blog}.member? d.justPath
      e.q['set'] = 'page'  # post-range in date-order
      e.q['local'] = true  # hostname-specific
    R['//'+e['SERVER_NAME']+'/blog'].setEnv(e).response
    end}

  # new post
  GET['/blog/post'] = -> d,e {
    [200,{'Content-Type'=>'text/html'},
     [H(['title',
         {_: :form, method: :POST,
           c: [{_: :input, name: Title},
               {_: :input, name: Type, value: SIOCt+'BlogPost', type: :hidden},
               {_: :input, name: :section, type: :hidden},
               {_: :input, type: :submit, value: :create}]}])]]}

#  base = R[host+Time.now.strftime('/%Y/%m/%d/')+URI.escape(title.gsub /[?#\s\/]/,'_')] # base URI
#  base.jsonDoc.ln_s R[host + '/blog/' + Time.now.iso8601[0..18].gsub('-','/') + '.e'] # datetime-index

  View[SIOCt+'BlogPost'] = -> g,e {
    g.map{|u,r|
      {class: :blogpost,
        c: [{_: :a, href: u, c: {_: :h1, c: r[Title]}},
            r[Content]]}}}

end
