watch __FILE__
class R

  # traverse collection of blog-posts
  F['/blog/GET'] = -> d,e {
    e.q['set'] = 'depth' # post-range in date-order on host
    e.q['local'] = true   # hostname not global paths
    e.q['c'] = 8
    R['http://'+e['SERVER_NAME']+'/time'].env(e).response}

  # decode POSTed title, mint derived-URI, set title+type properties, continue to editor
  F['/blog/post/POST'] = -> d,e {
    host = 'http://' + e['SERVER_NAME']
    title = (Rack::Request.new d.env).params['title']
    base = R[host+Time.now.strftime('/%Y/%m/%d/')+URI.escape(title.gsub /[?#\s\/]/,'_')] # doc 
    post = base.a '#'                                                              # editable resource
    post[Type] = R[SIOCt+'BlogPost']; post[Title] = title                          # add type-tag & title
    base.ef.ln_s R[host + '/time/' + Time.now.iso8601[0..18].gsub('-','/') + '.e'] # add to datetime-index
    [303,{'Location' => (base+"?prototype=sioct:BlogPost&graph=edit&mono").uri},[]]}

  # POST post-title to /blog/post
  F['/blog/post/GET'] = -> d,e {
    [200,{'Content-Type'=>'text/html'},
     [H(['title',
         {_: :form, method: :POST,
           c: [{_: :input, name: :title, style: "font-size:1.6em;width:48ex"},
               {_: :input, type: :submit, value: ' go '}
              ]}])]]}

  F['view/'+SIOCt+'BlogPost']=->g,e{F['example/blogview'][g,e]}

  F['example/blogview']=->g,e{
    g.map{|u,r|
      case u # match against URIs for customized view
      when /artery.wbur/ # compact whitespace a bit
        r[Content] = {class: :WBUR, c: [{_: :style, c: ".WBUR p {margin:0}"},r[Content]]}
        F['view/base'][{u => r},e]

      when /boston\.com/ # crop sharebuttons
       (Nokogiri::HTML.parse r[Content][0]).css('p')[0].do{|p|r[Content]=p.inner_html}
        F['view/base'][{u => r},e]

      when /flickr/
        r[Content]

      when /reddit/ # minimal view
        F['view/'+SIOCt+'BoardPost'][{u => r},e]

      when /universalhub/  # logo + trim spacehogging tagjunk
        c = Nokogiri::HTML.fragment r[Content][0]
        c.css('section').map{|x|x.remove}
        {c: [{_: :a, href: r['http://purl.org/rss/1.0/link'][0].R.uri,
               c: [{_: :img, src: '/logos/uhub.png',style: 'position:absolute;top:-93px'},
                   {_: :h2, style: 'color:#000;margin:0',c: r[Title]}]},c.to_s],
          style: 'float:left;max-width:40em;position:relative;background-color:#fff;border-color:#eee;margin-top:93px;margin-right:.3em;padding-top:0;border-style:dotted;border-width:.3em;border-radius:0 .8em .8em .8em'}
      else
        F['view/base'][{u => r},e]
      end}}

end
