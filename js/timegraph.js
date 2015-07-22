Element.prototype.on = function(b,f){this.addEventListener(b,f,false); return this}
NodeList.prototype.map = function(f,a){for(var i=0,l=this.length;i<l;i++) f.apply(this[i],a); return this}
NodeList.prototype.on = function(){return this.map(Element.prototype.on,arguments)}

var nodes = {};
var height = 180;
var width = window.innerWidth;
var middle = height / 2;

arcs.forEach(function(link) { // unique nodes from arc-list
  link.source = nodes[link.source] || (
      nodes[link.source] = {uri: link.source,
			    color: link.sourceColor,
			    name:  link.sourceName,
			    size: 16,
			    pos: link.sourcePos * (width - 42) + 21,
			   });
  link.target = nodes[link.target] || (
      nodes[link.target] = {uri: link.target,
			    color: link.targetColor,
			    name:  link.targetName,
			    size: 16,
			    pos: link.targetPos * (width - 42) + 21,
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
svg.append('rect').attr('height',height).attr('id','cursorB').style('fill','#224').attr('width',2).attr('x',width);

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
    .attr("width", function(d) { return d.size; })
    .attr("x",function(d) { return d.size * -1 + 12.5; })
    .attr("height", 9)
    .attr("ry",4);

node.append("text")
    .attr('x',-30)
    .attr('transform','rotate(90)')
    .style("fill", '#e8e8e8')
    .text(function(d) { return d.name; });

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

// cursor
svg.append('rect').attr('height',height).attr('id','cursor').style('fill','#eee').attr('width',10).attr('x',width);

var cursor = svg.select('#cursor')[0][0];
var cursorB = svg.select('#cursorB')[0][0];

window.onhashchange = function(e){
    var target = messages[window.location.hash.slice(1)];
    if(target) {
	force.resume();
	target.y = target.py = middle;
	cursor.setAttribute('x', target.pos);
    }
}

// find nearest node to mouse/tap-point
function findNode(event) {
    var x = null;
    if (event.targetTouches) {
	x = event.targetTouches[0].clientX;
    } else {
	x = event.clientX;
    }
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

document.addEventListener("keydown",function(e){

    // arrow-key navigation
    if((e.keyCode==37) || (e.keyCode==39)) {
	var next = null;
	var curID = window.location.hash.slice(1);
	var cur = document.getElementById(curID);

	if(cur) {
	    if(e.keyCode == 37) // left
		next = cur.previousSibling;
	    if(e.keyCode == 39) // right
		next = cur.nextSibling;
	} else {
	    next = document.querySelector('[id]');
	};
	console.log('cur',cur);
	console.log('curID',curID);
	console.log('next',next);
	if(next) {
	    window.location.hash = next.id;
	    e.preventDefault();
	};

	return false;
    };
},false)

var timegraph = document.getElementById('timegraph');
timegraph.addEventListener("mousemove",findNode);
timegraph.addEventListener("touchmove",findNode);
timegraph.addEventListener("click",findNode);
document.querySelectorAll(".mail").on("click",function(){window.location.hash=this.getAttribute("id");});
