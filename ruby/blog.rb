#watch __FILE__
class R

  # traversible blog-post collection
  # mountable on site-root GET['host/'] = GET['/blog']
  GET['/blog'] = -> d,e {
    if %w{/ /blog}.member? d.justPath
      e.q['set'] = 'page'  # post-range in date-order
      e.q['local'] = true  # hostname-specific
    R['//'+e['SERVER_NAME']+'/blog'].setEnv(e).response
    end}

  # prompt for title of new post
  GET['/blog/post'] = -> d,e {
    [200,{'Content-Type'=>'text/html'},
     [H(['title',
         {_: :form, method: :POST,
           c: [{_: :input, name: :title, style: "font-size:1.6em;width:48ex"},
               {_: :input, type: :submit, value: ' go '}
              ]}])]]}

  # mint URI (date and name), insert title+type to db, forward to default editor
  POST['/blog/post'] = -> d,e {
    host = '//' + e['SERVER_NAME']
    title = (Rack::Request.new d.env).params['title'] # decode POST-ed title
    base = R[host+Time.now.strftime('/%Y/%m/%d/')+URI.escape(title.gsub /[?#\s\/]/,'_')] # doc URI
    post = base.a '#'                # resource URI
    post[Type] = R[SIOCt+'BlogPost'] # add SIOC post-type
    post[Title] = title              # add Title
    post.snapshot
    base.jsonDoc.ln_s R[host + '/blog/' + Time.now.iso8601[0..18].gsub('-','/') + '.e'] # datetime-index
    [303,{'Location' => (base+"?prototype=sioct:BlogPost&view=edit&mono").uri},[]]}

  View[SIOCt+'BlogPost'] = -> g,e {
    g.map{|u,r|
      {class: :blogpost, c: [{_: :a, href: u, c: {_: :h1, c: r[Title]}}, r[Content]]}
    }}

end
