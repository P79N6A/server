
var vis = new pv.Panel()
    .width(1440)
    .height(510)
    .bottom(90);

var arc = vis.add(pv.Layout.Arc)
    .nodes(d.nodes)
    .links(d.links)
    .sort(function(a, b) a.group == b.group
        ? b.linkDegree - a.linkDegree
        : b.group - a.group);

arc.link.add(pv.Line);

arc.node.add(pv.Dot)
    .size(function(d) d.linkDegree + 4)
    .fillStyle(pv.Colors.category19().by(function(d) d.group))
    .strokeStyle(function() this.fillStyle().darker());

arc.label.add(pv.Label)

vis.render();

