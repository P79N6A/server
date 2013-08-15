class E
  
  fn '/search/GET',->e,r{
    r.q['graph'] = 'roonga'
    e.response
  }

  fn 'head/search',->d,e{[{_: :title, c: e.q['q']},(Fn 'head.formats',e)]}

  fn 'view/search',->d,e{
    [H.css('/css/search'),H.js('/js/search'),
     (Fn 'view/search/form',e.q,e),'<br><br>',
     (Fn 'view/page',d,e)]}

  fn 'view/search/form',-> q=nil,e { q||={}
    {:class => :form,
      c: {_: :form, action: e['REQUEST_PATH'],
        c: [{_: :input, name: :q, value: q['q']}, # search box
            q.update(q['view'] ? {} : {'view' => 'search'}). # show searchbox above results unless other view specified
            except('q','start','uri'). # new query & offset for this search
            map{|a,s|
              {_: :input, name:  a, value: s, :type => :hidden}}]}}}

  # construct p/o index-traversal links
  fn 'view/linkPO',->d,e{
    ['<style>a {background-color: #000;text-decoration:none;border-style:dotted;border-width:.1em;border-color:#fff;;color:#fff;font-size:1.3em;border-radius:.62em;padding:.1em}
div {display:block; padding:.3em}</style>',
     {_: :h3, c: e['uri']},{_: :br},
     d.map{|u,r|
      {c: {_: :a, href: r.url+'?set=indexPO&p='+e['uri']+'&view=page&views=timegraph,mail&v=multi&c=8', c: u}}
    }]}

end
