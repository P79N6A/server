var nodes = {};
var height = 150;
var width = window.innerWidth;
var middle = height / 2;
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
    .charge(-16)
    .on("tick", tick)
    .start();

var svg = d3.select("body").append("svg")
    .attr("width", width)
    .attr("height", height);
svg.append('rect').attr('height',height).attr('class','cursor').style('fill','#ccc').attr('width',10).attr('x',width);
var cursor = svg.select('.cursor')[0][0];


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

node.append("rect")
    .style("fill", function(d) { return d.color; })
    .attr("width", function(d) { return d.size; })
    .attr("x",function(d) { return d.size * -1 + 10; })
    .attr("height", 9)
    .attr("rx",4)
    .attr("ry",4);

node.append("text")
    .attr('y',2).attr('x',-25)
    .attr('transform','rotate(90)')
    .style("fill", '#ccc')
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

function click(d) {
    d.y = middle;
    d.py = middle;
    cursor.setAttribute('x', d.pos);
    var uri = d.uri
    if(uri) {	
	if(document.getElementById(uri)) {
	    window.location.hash = uri
	} else {
	    //	window.location = uri
	}
    }
}

function mouseover(d) {window.location.hash = d.uri}

document.addEventListener("DOMContentLoaded", function(){
    var nodeLen = node[0].length;
    var nodeLast = nodeLen - 1;
    var nodeIdx = 0;
    document.addEventListener("keydown",function(e){
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
	var t = node[0][nodeIdx];
	t.__onclick();
    },false)}, false);
