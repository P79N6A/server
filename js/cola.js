
var nodes = {};

links.forEach(function(link) {
  link.source = nodes[link.source] || (nodes[link.source] = {uri: link.source, name: (link.sourceName||link.source)});
  link.target = nodes[link.target] || (nodes[link.target] = {uri: link.target, name: (link.targetName||link.target)});
});

var width = 320,
    height = 720;

var force = cola.d3adaptor()
    .avoidOverlaps(true)
    .nodes(d3.values(nodes))
    .links(links)
    .size([width, height])
    .flowLayout("y", 33)
    .symmetricDiffLinkLengths(24)
    .on("tick", tick)
    .start(10,20,20);

var svg = d3.select("body").append("svg")
    .attr("width", width)
    .attr("height", height);

var link = svg.selectAll(".link")
    .data(force.links())
  .enter().append("line")
    .attr("class", "link");

var node = svg.selectAll(".node")
    .data(force.nodes())
  .enter().append("g")
    .attr("class", "node")
    .on("click", click)
    .call(force.drag);

node.append("circle")
    .attr("r", 8);

node.append("text")
    .attr("x", 12)
    .attr("dy", ".35em")
    .text(function(d) { return d.name; });

function tick() {
  link
      .attr("x1", function(d) { return d.source.x; })
      .attr("y1", function(d) { return d.source.y; })
      .attr("x2", function(d) { return d.target.x; })
      .attr("y2", function(d) { return d.target.y; });

  node
      .attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; });
}

function click(d) {
    window.location.hash = d.uri
}
