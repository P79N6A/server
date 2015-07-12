var nodes = {};
var height = 150;
var width = window.innerWidth;
links.forEach(function(link) { // unique nodes from arc-list
  link.source = nodes[link.source] || (
      nodes[link.source] = {uri: link.source,
			    color: link.sourceColor,
			    name:  link.sourceName,
			    size: 16,
			    pos: link.sourcePos * (width - 32) + 16,
			   });
  link.target = nodes[link.target] || (
      nodes[link.target] = {uri: link.target,
			    color: link.targetColor,
			    name:  link.targetName,
			    size: 16,
			    pos: link.targetPos * (width - 32) + 16,
			   });
});

var force = d3.layout.force()
    .nodes(d3.values(nodes))
    .links(links)
    .size([width,height])
    .linkDistance(8)
    .charge(-32)
    .on("tick", tick)
    .start();

var svg = d3.select("body").append("svg")
    .attr("width", width)
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
    .attr('y',10).attr('x',8)
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
    link.attr("y1", function(d) { return d.source.y + 4; })
	.attr("x1", function(d) { return (d.source.pos || 0); })
	.attr("y2", function(d) { return d.target.y + 4; })
	.attr("x2", function(d) { return (d.target.pos || 0); });

    node.attr("transform", function(d) { return "translate(" + (d.pos || 0) + "," + d.y + ")"; });
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
