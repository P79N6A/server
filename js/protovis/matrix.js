var color = pv.Colors.category19().by(function(d) d.group);

var vis = new pv.Panel()
    .width(1000)
    .height(1000)
    .top(90)
    .left(90);

var layout = vis.add(pv.Layout.Matrix)
    .nodes(d.nodes)
    .links(d.links)
    .sort(function(a, b) b.group - a.group);

layout.link.add(pv.Bar)
    .fillStyle(function(l) l.linkValue
        ? ((l.targetNode.group == l.sourceNode.group)
        ? color(l.sourceNode) : "#555") : "#eee")
    .antialias(false)
    .lineWidth(1);

layout.label.add(pv.Label)
    .textStyle(color);

vis.render();