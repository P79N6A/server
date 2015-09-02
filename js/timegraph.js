
document.addEventListener("DOMContentLoaded", function(){
var svg = d3.select("#timegraph > svg")
var nodes = {};
var height = svg[0][0].clientHeight || 600;
var width = svg[0][0].clientWidth || 128;
var center = width / 2;
    var targetCount = {};
arcs.forEach(function(link) { // bind node-table and link data
    targetCount[link.target] = typeof(targetCount[link.target])=="number" ? (targetCount[link.target] + 1) : 0
    link.source = nodes[link.source] || (
      nodes[link.source] = {uri: link.source,
			    name: link.sourceLabel,
			    pos: height - link.sourcePos * height,
			   });
  link.target = nodes[link.target] || (
      nodes[link.target] = {uri: link.target,
			    name: link.targetLabel,
			    pos: height - link.targetPos * height,
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
	    return (targetCount[d.uri] > 0 ? d.name : '');
	})
	.attr('x',8).attr('y',3)
	.attr("name", function(d) { return d.name; });

// URI -> item
var messages = {}
node.each(function(item,index){
    messages[item.uri] = item;
});

function tick() {
    link.attr("x1", function(d) {
	return d.source.x + 2;
    })
	.attr("y1", function(d) { return (d.source.pos || 0); })
	.attr("x2", function(d) {
	    return d.target.x + 2;
	})
	.attr("y2", function(d) { return (d.target.pos || 0); });

    node.attr("transform", function(d) { return "translate(" + d.x + "," + (d.pos || 0) + ")"; });
}

// create cursor
    svg.append('rect').attr('width',16).attr('id','cursor').style('fill','#eee').attr('height',3).attr('x',12).attr('y',height);
var cursor = svg.select('#cursor')[0][0];

window.addEventListener("hashchange",function(e){ // move cursor to current focus
    var id = window.location.hash.slice(1);
    var vz = messages[id] || messages[window.location.hash];
    if(vz) {
	force.resume();
	vz.x = vz.px = center;
	cursor.setAttribute('y', vz.pos + 2);
    }
});

// find nearest node to mouse/tap-point
function findNode(event) {
    event.preventDefault();
    event.stopPropagation();
    var y = null;
    if (event.targetTouches) {
	y = event.targetTouches[0].offsetY;
    } else {
	y = event.offsetY;
    }
    var found = null;
    var distance = width;
    node.each(function(item,index){
	var d = Math.abs(y - item.pos);
	if(d <= distance){
	    distance = d;
	    found = item;
	}
    });
    if(found)
	window.location.hash = found.uri;
}

var timegraph = document.getElementById('timegraph');
timegraph.addEventListener("mousemove",findNode);
timegraph.addEventListener("touchmove",findNode);
timegraph.addEventListener("click",findNode);

}, false);
