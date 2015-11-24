document.addEventListener("DOMContentLoaded", function(){
    var svg = d3.select("#timegraph > svg")
    var nodes = {};
    var width = svg[0][0].clientWidth || 600;
    var height = svg[0][0].clientHeight || 128;
    var center = width / 2;
    var targetCount = {};
    arcs.forEach(function(link) { // bind node-table and link data
	targetCount[link.target] = typeof(targetCount[link.target])=="number" ? (targetCount[link.target] + 1) : 0
	link.source = nodes[link.source] || (
	    nodes[link.source] = {uri: link.source,
				  name: link.sourceLabel,
				  pos: link.sourcePos * width,
				 });
	link.target = nodes[link.target] || (
	    nodes[link.target] = {uri: link.target,
				  name: link.targetLabel,
				  pos: link.targetPos * width,
				 });
    });
    var force = d3.layout.force()
	.nodes(d3.values(nodes))
	.links(arcs)
	.size([width,height])
	.linkDistance(8)
	.charge(-24)
	.on("tick", tick)
	.start();

    var link = svg.selectAll(".link")
	.data(force.links())
	.enter().append("line")
	.attr("class", "link")
	.attr('name', function(d){return d.sourceLabel});

    var node = svg.selectAll(".node")
	.data(force.nodes())
	.enter().append("g")
	.attr("class", "node")
	.call(force.drag);
    
    node.append("rect")
	.attr("name", function(d) { return d.name; });

    node.append("text")
	.text(function(d) {
	    return (targetCount[d.uri] > 1 ? d.name : '');
	})
	.attr('x',8).attr('y',3)
	.attr("name", function(d) { return d.name; });

    function tick() {
	link.attr("y1", function(d) {
	    return d.source.y;
	})
	    .attr("x1", function(d) { return (d.source.pos || 0); })
	    .attr("y2", function(d) {
		return d.target.y;
	    })
	    .attr("x2", function(d) { return (d.target.pos || 0); });

	node.attr("transform", function(d) { return "translate(" + (d.pos || 0) + "," + d.y + ")"; });
    }

}, false);
