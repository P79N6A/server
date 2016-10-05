document.addEventListener("DOMContentLoaded", function(){
    var svg = d3.select("#timegraph > svg")
    var nodes = {};
    var width = svg[0][0].clientWidth || 360;
    var height = svg[0][0].clientHeight || 720;
    var center = width / 2;
    var targetCount = {};
    arcs.forEach(function(link) { // bind node-table and link data
	link.source = nodes[link.source] || (
	    nodes[link.source] = {uri: link.source,
				  name: link.sourceLabel,
				 });
	link.target = nodes[link.target] || (
	    nodes[link.target] = {uri: link.target,
				  name: link.targetLabel,
				 });
    });
    var force = d3.layout.force()
	.nodes(d3.values(nodes))
	.gravity(0.01)
	.links(arcs)
	.size([width,height])
	.on("tick", tick)
	.start();

    var link = svg.selectAll(".link")
	.data(force.links())
	.enter().append("line")
	.attr("class", "link")
	.on("click",function(e){
	    svg[0][0].style.position = 'fixed';
	    console.log(this,e);
	    window.location.hash=e.source.uri;
	})
	.attr('name', function(d){return d.sourceLabel});

    var node = svg.selectAll(".node")
	.data(force.nodes())
	.enter().append("g")
	.attr("class", "node")
	.call(force.drag);
    
    node.append("rect")
	.attr("name", function(d) { return d.name; });

    node.append("text")
	.text(function(d) {return d.name;})
	.attr('x',8).attr('y',3)
	.attr("name", function(d) { return d.name; })
	.on("click",function(e){
	    svg[0][0].style.position = 'fixed';
	    window.location.hash=e.uri;
	});

    function tick() {
	link.attr("y1", function(d) {
	    return d.source.y + 2;
	})
	    .attr("x1", function(d) {
		return d.source.x;
	    })
	    .attr("y2", function(d) {
		return d.target.y + 2;
	    })
	    .attr("x2", function(d) {
		return d.target.x;
	    });
	node.attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; });
    };

}, false);
