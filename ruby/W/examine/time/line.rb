class E

 ## SIMILE Timeline 
 #  http://www.simile-widgets.org/

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

  fn 'head/timeline',->d,e{
  ['<script>var t="'+e['REQUEST_PATH']+e.q.except('view','?').merge({format: 'application/timeline'}).qs+'"</script>',
   (H.js '/js/timeline'),
   (H.js 'http://api.simile-widgets.org/timeline/2.3.1/timeline-api')]}

  fn 'view/timeline',->d,e{'<div id="tl" class="timeline-default" style="height: 300px;"></div>'}

end
