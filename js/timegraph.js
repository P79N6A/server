var nodes = {};
var height = window.innerHeight
links.forEach(function(link) { // unique nodes from arc-list
  link.source = nodes[link.source] || (
      nodes[link.source] = {uri: link.source,
			    color: link.sourceColor,
			    name:  link.sourceName,
			    size: 16,
			    pos: link.sourcePos * (height - 16) + 8,
			   });
  link.target = nodes[link.target] || (
      nodes[link.target] = {uri: link.target,
			    color: link.targetColor,
			    name:  link.targetName,
			    size: 16,
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

var link = svg.selectAll(".link")
    .data(force.links())
    .enter().append("line")
    .attr("class", "link")
    .style('stroke', function(d){return (d.sourceColor || '#ccc')});

var node = svg.selectAll(".node")
    .data(force.nodes())
    .enter().append("g")
    .attr("class", "node")
    .on("mouseover", mouseover)
    .on("click", click)
    .call(force.drag);

node.append("text")
    .attr('y','-.2em').attr('x','-4.4em')
    .style("fill", function(d) { return d.color; })
    .text(function(d) { return d.name; });

node.append("rect")
    .style("fill", function(d) { return d.color; })
    .attr("width", function(d) { return d.size; })
    .attr("x",function(d) { return d.size * -1 + 10; })
    .attr("height", 9)
    .attr("rx",4)
    .attr("ry",4);

function tick() {
    link.attr("x1", function(d) { return d.source.x; })
	.attr("y1", function(d) { return (d.source.pos || 0); })
	.attr("x2", function(d) { return d.target.x; })
	.attr("y2", function(d) { return (d.target.pos || 0); });

    node.attr("transform", function(d) { return "translate(" + d.x + "," + (d.pos || 0) + ")"; });
}

function click(d) {
    var uri = d.uri
    if(document.getElementById(uri)) {
	window.location.hash = uri
    } else {
	window.location = uri
    }
}
function mouseover(d) {window.location.hash = d.uri}
