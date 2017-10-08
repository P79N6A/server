NodeList.prototype.map = function(f,a){
    for(var i=0, l=this.length; i<l; i++)
	f.apply(this[i],a);
    return this;
};
Element.prototype.attr = function(a,v){
    if(v){
	this.setAttribute(a,String(v));
	return this;
    } else {
	return this.getAttribute(a);
    };
};
document.addEventListener("DOMContentLoaded", function(){
    // construct selection-ring
    var first = null;
    var last = null;
    document.querySelectorAll('[id]').map(function(e){
	if(!first)
	    first = this;
	// link the list
	if(last){
	    this.attr('prev',last.attr('id'));
	    last.attr('next',this.attr('id'));
	};
	last = this;
    });
    if(first && last){ // complete the ring
	last.attr('next',first.attr('id'));
	first.attr('prev',last.attr('id'));
    };
    // keyboard navigation
    document.addEventListener("keydown",function(e){
	var jumpDoc = function(direction) {
	    var doc = document.querySelector("head > link[rel='"+direction+"']");
	    if(doc)
		window.location = doc.getAttribute('href');
	};
	var key = e.keyCode;
	if(e.getModifierState("Shift")) {
	    if(key==80) // [shift-p]rev page
		jumpDoc('prev');
	    if(key==78) // [shift-n]ext page
		jumpDoc('next');
	    if(key==85) // [shift-u]p to parent
		jumpDoc('up');
	    if(key==68) // [shift-d]own to children
		jumpDoc('down');
	    return null;
	};	
	if(key==80){ // [p]revious selection
	    loc = window.location.hash
	    if(loc) {
		cur = document.querySelector(loc);
		if(!cur)
		    cur = first;
	    } else {
		cur = first
	    };
	    var p = cur.attr('prev');
	    window.location.hash = p;
	    e.preventDefault();
	};
	if(key==78){ // [n]ext selection
	    var loc = window.location.hash;
	    var cur = null;
	    if(loc)
		cur = document.querySelector(loc);
	    if(!cur) {
		window.location.hash = first.attr('id');
	    } else {
		window.location.hash = cur.attr('next');
	    };
	    e.preventDefault();
	};
	if(key==13||key==39){ // [enter] go
	    // find identifier
	    loc = window.location.hash;
	    if(loc){
		// find element
		cur = document.querySelector(loc);
		if(cur){
		    // find href
		    href = cur.attr('href');
		    // go
		    if(href)
			window.location = href;
		};
	    };
	};
	if(key==83){ // [s]ort type
	    var sel = document.querySelector('.selected');
	    if(sel){
		var next = sel.nextSibling || document.querySelector('tr > th[href]');
		if(next)
		    window.location = next.getAttribute('href');
	    };
	};
	if(key==82){ // [r]everse sort
	    window.location = document.querySelector('.selected').getAttribute('href');
	};
    },false);
}, false);