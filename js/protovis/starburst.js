var vis = new pv.Panel()
    .width(900)
    .height(900)
    .bottom(-80);

var partition = vis.add(pv.Layout.Partition.Fill)
    .nodes(pv.dom(d).nodes())
    .size(function(d) d.nodeValue)
    .order("descending")
    .orient("radial");

partition.node.add(pv.Wedge)
    .fillStyle(pv.Colors.category19().by(function(d) d.parentNode && d.parentNode.nodeName))
    .strokeStyle("#fff")
    .lineWidth(.5)
    .event("click", function(i){
	var c=[],a=i
	while(a.parentNode){
	    c.unshift(a.nodeName)
	    a = a.parentNode}
	document.location.href='/'+c.join('/')+(i.childNodes.length == 0 ? '' : '/??=du&v=starburst')});

partition.label.add(pv.Label)
    .visible(function(d) d.angle * d.outerRadius >= 6);

vis.render();

/* Update the layout's size method and re-render. */
function update(method) {
  switch (method) {
    case "byte": partition.size(function(d) d.nodeValue); break;
    case "file": partition.size(function(d) d.firstChild ? 0 : 1); break;
  }
  vis.render();
}

