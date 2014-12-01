var nodes = {};

links.forEach(function(link) { // unique nodes from arc-list
  link.source = nodes[link.source] || (
      nodes[link.source] = {uri: link.source,
			    color: link.sourceColor,
			    name:  link.sourceName});
  link.target = nodes[link.target] || (
      nodes[link.target] = {uri: link.target,
			    color: link.targetColor,
			    name:  link.targetName});
});

var force = d3.layout.force()
    .nodes(d3.values(nodes))
    .links(links)
    .size([360,768])
    .linkDistance(18)
    .charge(-250)
    .on("tick", tick)
    .start();

var svg = d3.select("body").append("svg")
    .attr("width", 480)
    .attr("height", 768);

document.querySelector("body").addEventListener("click", function(e){ // toggle SVG focus
    if (e.target.nodeName=='BODY'||e.target.nodeName=='svg'){
	var s = document.querySelector('svg')
	s.style.zIndex = s.style.zIndex == 2 ? -1 : 2
    }
},false);

svg.append('svg:defs').append('svg:marker')
    .attr('id', 'end-arrow')
    .attr('viewBox', '0 -5 10 10')
    .attr("refX", 36)
    .attr('markerWidth', 5)
    .attr('markerHeight', 5)
    .attr('orient', 'auto')
    .append('svg:path')
    .attr('d', 'M0,-5L10,0L0,5')
    .attr('fill', '#999');

var link = svg.selectAll(".link")
    .data(force.links())
    .enter().append("line")
    .attr("class", "link")
    .style('marker-end', 'url(#end-arrow)');

var node = svg.selectAll(".node")
    .data(force.nodes())
    .enter().append("g")
    .attr("class", "node")
    .on("mouseover", mouseover)
    .on("click", click)
    .call(force.drag);

node.append("text")
    .attr("x", 12)
    .attr("dy", ".35em")
    .style("fill", function(d) { return d.color; })
    .text(function(d) { return d.name; });
/*
node.insert("rect","text").each(function(){
    this.setAttribute("width", this.nextSibling.getBBox().width)
    this.setAttribute("height", 10)
    this.setAttribute("x", 12)
    this.setAttribute("y", -5)})
*/
node.append("circle")
    .style("fill", function(d) { return d.color; })
    .attr("r", 9);

function tick() {
  link.attr("x1", function(d) { return d.source.x; })
      .attr("y1", function(d) { return d.source.y; })
      .attr("x2", function(d) { return d.target.x; })
      .attr("y2", function(d) { return d.target.y; });

  node.attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; });
}

function click(d) {
    if(window.location.hash.slice(1) == d.uri) {
	window.location = d.uri
    } else {
	window.location.hash = d.uri
    }
}

function mouseover(d) {
    window.location.hash = d.uri
}
