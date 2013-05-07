class E

  # time-range endpoint
  fn '/t/GET',->e,r{ m={}; r=r.q
    (E Date).pIndex.subtree(
     (r['c']&&r['c'].to_i.max(256)+1 || 8),                     # size
     (r['d']&&r['d'].match(/^(a|de)sc$/)&&r['d'].to_sym||:desc),# direction
     (r['t']&&'/u/'+r['t'].gsub(/\D+/,'/'))                     # offset
     ).do{|t|
         a,b=t[0],t.size>1&&t.pop; desc,asc=r['d']&&r['d']=='asc'&&[a,b]||[b,a] 
         m['prev']={'uri' => 'prev','url' => '/t', 'd' => 'desc','t' => desc.base} if desc
         m['next']={'uri' => 'next','url' => '/t', 'd' => 'asc', 't' => asc.base}  if asc
      t.map{|t| t.subtree.map(&:ro).map{|r| m[r.uri]=r }}}
     e.resources m}

 ## SIMILE Timeline 

  # JSON format
  fn Render+'application/timeline',->d,e{
    {dateTimeFormat: 'iso8601',
      events: d.values.map{|r|
        r[Date].do{|d|
          {description: r.uri,
          title: r[Title],
          start: [*d][0],
          link: r.url,
        }}}.compact}.to_json}

  fn 'head/simile-timeline',->d,e{
  ['<script>var t="'+e['REQUEST_PATH']+e.q.except('view','?').merge({format: 'application/timeline'}).qs+'"</script>',
   (H.js '/js/timeline'),
   (H.js 'http://api.simile-widgets.org/timeline/2.3.1/timeline-api')]}

  fn 'view/simile-timeline',->d,e{'<div id="tl" class="timeline-default" style="height: 300px;"></div>'}

end
