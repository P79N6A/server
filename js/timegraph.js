var nodes = {};
var height = 150;
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
    .charge(-18)
    .on("tick", tick)
    .start();

var svg = d3.select("body").append("svg")
    .attr("id","timegraph")
    .attr("width", width)
    .attr("height", height)

var link = svg.selectAll(".link")
    .data(force.links())
    .enter().append("line")
    .attr("class", "link")
    .style('stroke', function(d){return (d.sourceColor || '#ccc')});

var node = svg.selectAll(".node")
    .data(force.nodes())
    .enter().append("g")
    .attr("class", "node")
    .on("mouseover", moveCursor)
    .on("click", moveCursor)
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
svg.append('rect').attr('height',height).attr('class','cursor').style('fill','#eee').attr('width',10).attr('x',width);

var cursor = svg.select('.cursor')[0][0];
var cursorCSS = document.getElementById('highlight')

function moveCursor(d) {
    force.resume();
    d.y = middle;
    d.py = middle;
    cursor.setAttribute('x', d.pos);
    var r = document.getElementById(d.uri)
    if(r){
	cursorCSS.textContent = "tr[id='"+d.uri + "'] > td:first-child {background-color: #fff}";
	window.location.hash = d.uri;
	document.body.scrollTop = r.offsetTop;
    }
}

var nodeLen = node[0].length;
var nodeLast = nodeLen - 1;
var nodeIdx = 0;

document.addEventListener("keydown",function(e){

    // arrow-key navigation
    if((e.keyCode==37)||(e.keyCode==39)) {

	// left
	if(e.keyCode == 37){
	    if(nodeIdx <= 0) {
		nodeIdx = nodeLast;
	    } else {
		nodeIdx = nodeIdx - 1;
	    };
	};
	// right
	if(e.keyCode == 39){
	    if(nodeIdx >= nodeLast){
		nodeIdx = 0;
	    } else {
		nodeIdx = nodeIdx + 1;
	    }
	    
	};
	node[0][nodeIdx].__onclick();
    };
},false)

function findNode(event) {
    var closest = null;
    var distance = width;
    node.each(function(item,index){
	var d = Math.abs(event.clientX - item.pos);
	if(d <= distance){
	    distance = d;
	    closest = item;
	}
    });
    moveCursor(closest);
}

var timegraph = document.getElementById('timegraph');
timegraph.addEventListener("mouseover",findNode);
timegraph.addEventListener("mouseover",findNode);

