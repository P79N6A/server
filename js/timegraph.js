var nodes = {};
var height = 128;
var width = window.innerWidth;
var middle = height / 2;

arcs.forEach(function(link) { // populate node-table from triples
  link.source = nodes[link.source] || (
      nodes[link.source] = {uri: link.source,
			    color: link.sourceColor,
			    pos: link.sourcePos * width,
			   });
  link.target = nodes[link.target] || (
      nodes[link.target] = {uri: link.target,
			    color: link.targetColor,
			    pos: link.targetPos * width,
			   });
});

var force = d3.layout.force()
    .nodes(d3.values(nodes))
    .links(arcs)
    .size([width,height])
    .linkDistance(8)
    .charge(-20)
    .on("tick", tick)
    .start();

var svg = d3.select("body").append("svg")
    .attr("id","timegraph")
    .attr("width", width)
    .attr("height", height);

// input-location cursor
svg.append('rect').attr('height',middle).attr('id','cursorB').style('fill','#ddd').attr('width',1).attr('x',width).attr('y',middle);

var link = svg.selectAll(".link")
    .data(force.links())
    .enter().append("line")
    .attr("class", "link")
    .style('stroke', function(d){return (d.sourceColor || '#ccc')});

var node = svg.selectAll(".node")
    .data(force.nodes())
    .enter().append("g")
    .attr("class", "node")
    .call(force.drag);

node.append("rect")
    .style("fill", function(d) { return d.color; })
    .attr("width", 9)
    .attr("height", 9)
    .attr("ry",4);

// URI -> item
var messages = {}
node.each(function(item,index){
    messages[item.uri] = item;
});

function tick() {
    link.attr("y1", function(d) {
	return d.source.y + 4;
    })
	.attr("x1", function(d) { return (d.source.pos || 0); })
	.attr("y2", function(d) {
	    return d.target.y + 4;
	})
	.attr("x2", function(d) { return (d.target.pos || 0); });

    node.attr("transform", function(d) { return "translate(" + (d.pos || 0) + "," + d.y + ")"; });
}

// create cursor
svg.append('rect').attr('height',86).attr('id','cursor').style('fill','#fff').attr('width',5).attr('x',width).attr('y',42);
var cursor = svg.select('#cursor')[0][0]; // nearest-match cursor
var cursorB = svg.select('#cursorB')[0][0]; // raw-input cursor

window.addEventListener("hashchange",function(e){ // move cursor to current focus
    var id = window.location.hash.slice(1);
    var vz = messages[id] || messages[window.location.hash];
    if(vz) {
	force.resume();
	vz.y = vz.py = middle;
	cursor.setAttribute('x', vz.pos);
    }
});

// find nearest node to mouse/tap-point
function findNode(event) {
    event.preventDefault();
    event.stopPropagation();
    var x = null;
    if (event.targetTouches) {
	x = event.targetTouches[0].clientX;
    } else {
	x = event.clientX;
    }
    cursorB.setAttribute('x',x);
    var found = null;
    var distance = width;
    node.each(function(item,index){
	var d = Math.abs(x - item.pos);
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

