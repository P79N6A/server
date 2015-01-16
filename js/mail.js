var nodes = {};
var height = window.innerHeight
links.forEach(function(link) { // unique nodes from arc-list
  link.source = nodes[link.source] || (
      nodes[link.source] = {uri: link.source,
			    color: link.sourceColor,
			    name:  link.sourceName,
			    size: (link.sourceSize || 17),
			    pos: link.sourcePos * (height - 16) + 8,
			   });
  link.target = nodes[link.target] || (
      nodes[link.target] = {uri: link.target,
			    color: link.targetColor,
			    name:  link.targetName,
			    size: 17,
			    pos: link.targetPos * (height - 16) + 8,
			   });
});

var force = d3.layout.force()
    .nodes(d3.values(nodes))
    .links(links)
    .size([333,height])
    .linkDistance(12)
    .charge(-64)
    .on("tick", tick)
    .start();

var svg = d3.select("body").append("svg")
    .attr("width", window.innerWidth)
    .attr("height", height);

svg.append('svg:defs').append('svg:marker')
    .attr('id', 'end-arrow')
    .attr('viewBox', '0 -5 10 10')
    .attr("refX", 10)
    .attr('markerWidth', 3)
    .attr('markerHeight', 3)
    .attr('orient', 'auto')
    .append('svg:path')
    .attr('d', 'M0,-5L10,0L0,5')
    .attr('fill', '#ddd');

var link = svg.selectAll(".link")
    .data(force.links())
    .enter().append("line")
    .attr("class", "link")
    .style('stroke', function(d){
	return (d.arcColor || '#ccc')
    })
    .style('marker-end', 'url(#end-arrow)');

var node = svg.selectAll(".node")
    .data(force.nodes())
    .enter().append("g")
    .attr("class", "node")
    .on("mouseover", mouseover)
    .on("click", click)
    .call(force.drag);

node.append("text")
    .attr('y','-.2em')
    .style("fill", function(d) { return d.color; })
    .text(function(d) { return d.name; });

node.append("rect")
    .style("fill", function(d) { return d.color; })
    .attr("width", function(d) { return d.size; }).attr("x",function(d) { return d.size * -1 + 10; }).attr("height", 9);

function tick() {
    link.attr("x1", function(d) { return d.source.x; })
	.attr("y1", function(d) { return (d.source.pos || 0); })
	.attr("x2", function(d) { return d.target.x; })
	.attr("y2", function(d) { return (d.target.pos || 0); });

    node.attr("transform", function(d) { return "translate(" + d.x + "," + (d.pos || 0) + ")"; });
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
