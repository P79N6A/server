#watch __FILE__
class R

  # traverse collection of blog-posts
  F['/blog/GET'] = -> d,e {
    e.q['set'] = 'depth' # post-range in date-order
    e.q['local'] = true  # hostname-specific paths
    e.q['c'] = 8         # count
    R['http://'+e['SERVER_NAME']+'/time'].env(e).response}

  # post name <input>
  F['/blog/post/GET'] = -> d,e {
    [200,{'Content-Type'=>'text/html'},
     [H(['title',
         {_: :form, method: :POST,
           c: [{_: :input, name: :title, style: "font-size:1.6em;width:48ex"},
               {_: :input, type: :submit, value: ' go '}
              ]}])]]}

  # mint URI using date and cleaned name, set a few attrs and forward to default editor
  F['/blog/post/POST'] = -> d,e {
    host = 'http://' + e['SERVER_NAME']
    title = (Rack::Request.new d.env).params['title'] # decode POST-ed title
    base = R[host+Time.now.strftime('/%Y/%m/%d/')+URI.escape(title.gsub /[?#\s\/]/,'_')] # doc URI
    post = base.a '#'                # resource URI
    post[Type] = R[SIOCt+'BlogPost'] # add SIOC post-type
    post[Title] = title              # add Title
    base.ef.ln_s R[host + '/time/' + Time.now.iso8601[0..18].gsub('-','/') + '.e'] # datetime-index
    [303,{'Location' => (base+"?prototype=sioct:BlogPost&graph=edit&mono").uri},[]]}

end
