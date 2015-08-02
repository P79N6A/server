
Element.prototype.on = function(b,f){this.addEventListener(b,f,false); return this}
NodeList.prototype.map = function(f,a){for(var i=0,l=this.length;i<l;i++) f.apply(this[i],a); return this}
NodeList.prototype.on = function(){return this.map(Element.prototype.on,arguments)}

document.addEventListener("DOMContentLoaded", function(){ // wait till DOM nodes exist
    // tap/click/mouseover to focus
    var focusNode = function(){
	window.location.hash = this.getAttribute("id");
    };
    var gotoNode = function(){
	var loc = window.location.hash.slice(1);
	var id = this.getAttribute("id");
	if(loc == id && this.hasAttribute('href')){
	    window.location = this.getAttribute('href');
	} else {
	    window.location.hash = id;
	    var resource = document.getElementById(id);
	    if(resource)
		window.scrollTo(resource.offsetLeft + (resource.clientWidth / 2) - (window.width / 2), window.scrollY);
	};
    };
    var selectable = document.querySelectorAll("[selectable][id]");
    selectable.on("click",gotoNode);
    selectable.on("mouseover",focusNode);
});
			  
// arrow-key navigation
document.addEventListener("keydown",function(e){
    var resource = null;
    var id = window.location.hash.slice(1);
    if(id)
	resource = document.getElementById(id);

    var prev = function() {
	if(resource) {
	    var sib = resource.previousSibling;
	    if(sib) { // previous entry
		var prevId = sib.getAttribute("id");
		if(prevId)
		    window.location.hash = prevId;
	    } else { // wrap
		var loop = resource.parentNode.lastChild;
		if(loop)
		    window.location.hash = loop.getAttribute("id");
	    };
	}
    };

    var next = function() {
	if(resource) {	// focused resource
	    var explicitNext = resource.getAttribute("next");
	    if(explicitNext) { // next by declaration
		window.location = explicitNext;
	    } else {
		var nextSibling = resource.nextSibling;
		if(nextSibling) { // next in sequence
		    var nextId = nextSibling.getAttribute("id");
		    if(nextId)
			window.location.hash = nextId;
		} else { // sequence-end, wrap around
		    var loop = resource.parentNode.firstChild;
		    if(loop)
			window.location.hash = loop.getAttribute("id");
		};
	    };
	} else { // no focused-resource, annoint one
	    var cur = document.querySelector('[id][selectable]');
	    if(cur)
		window.location.hash = cur.getAttribute('id');
	}
    };

    // select previous
    // <up-arrow>
    if(e.keyCode==38) {
	e.preventDefault();
	if (e.getModifierState("Shift")) {
	    next();
	} else {
	    prev();
	};
    };

    // select next
    // <down-arrow> <tab>
    if(e.keyCode==40 || e.keyCode==9){
	e.preventDefault();
	if (e.getModifierState("Shift")) {
	    prev();
	} else {
	    next();
	};
    };

    // exit
    // <left-arrow> <esc>
    if(e.keyCode==27 || e.keyCode==37){
	if(resource) {
	    var up = null;
	    var r = resource.parentNode;
	    while(r && r.nodeName != '#document' && !up) {
		if(r.hasAttribute('selectable'))
		    up = r.getAttribute('id');
		r = r.parentNode;
	    }
	    if(up){
		window.location.hash = up;
	    } else {
		window.history.back();
	    };
	} else {
	    window.history.back();
	};
    };

    // enter
    // <right-arrow>
    if(e.keyCode == 39){
	e.preventDefault();
	if(resource) {
	    var child = resource.querySelector('[id][selectable]');
	    var href = resource.getAttribute("href");
	    if(child){
		window.location.hash = child.getAttribute('id');
	    } else if(href) {
		document.location = href;
	    };
	};
    };
    // <enter>
    if(e.keyCode == 13){
	e.preventDefault();
	if(resource) {
	    var child = resource.querySelector('[id][selectable]');
	    var href = resource.getAttribute("href");
	    if(href){
		document.location = href;
	    } else if(child) {
		window.location.hash = child.getAttribute('id');
	    };
	};
    };

    // path/trail/history back
    if(e.keyCode==66 || e.keyCode==80) // b, p
	window.history.back();
    // forward
    if(e.keyCode==78) // n
	window.history.forward();

},false);
