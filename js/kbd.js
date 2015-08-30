
Element.prototype.on = function(b,f){this.addEventListener(b,f,false); return this}
NodeList.prototype.map = function(f,a){for(var i=0,l=this.length;i<l;i++) f.apply(this[i],a); return this}
NodeList.prototype.on = function(){return this.map(Element.prototype.on,arguments)}

document.addEventListener("DOMContentLoaded", function(){ // wait till DOM nodes exist
    // tap/click to focus
    var focusNode = function(e){
	var loc = window.location.hash.slice(1);
	var id = this.getAttribute("id");
	if(loc == id && this.hasAttribute('href')){ // jump to canonical location: tap while focused
	    window.location = this.getAttribute('href');
	} else {
	    window.location.hash = id;
	};
	e.stopPropagation();
    };
    var selectable = document.querySelectorAll("[selectable][id]");
    selectable.on("click",focusNode);
});
			  
// keyboard navigation
document.addEventListener("keydown",function(e){
    var resource = null;
    var id = window.location.hash.slice(1);
    if(id)
	resource = document.getElementById(id);
    var jumpDoc = function(direction) {
	var doc = document.querySelector("head > link[rel='"+direction+"']");
	if(doc)
	    window.location = doc.getAttribute('href');
    };
    var prevDoc = function() {jumpDoc('prev');}
    var nextDoc = function() {jumpDoc('next');}

    var prev = function() { // resource/item/entry
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
	    if(explicitNext) { // next by declaration, can jump document-contexts
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
	} else { // no focused-resource, find the first one
	    var cur = document.querySelector('[id][selectable]');
	    if(cur)
		window.location.hash = cur.getAttribute('id');
	}
    };

    if(e.keyCode==80) {
	e.preventDefault();
	if (e.getModifierState("Shift")) {
	    prevDoc(); // <shift-p>  previous (doc)
	} else {
	    prev(); // <p>  previous (resource)
	};
    };
    if(e.keyCode==78){
	e.preventDefault();
	if (e.getModifierState("Shift")) {
	    nextDoc(); // <shift-n> next (doc)
	} else {
	    next(); // <n> next (resource)
	};
    };
    if(e.keyCode==9){
	e.preventDefault();
	if (e.getModifierState("Shift")) {
	    prev(); // <shift-tab> previous (resource)
	} else {
	    next(); // <tab> next (resource)
	};
    };
   
    // exit context
    // <esc>
    if(e.keyCode==27){
	if(resource) { // in-doc context
	    var up = null;
	    var r = resource.parentNode;
	    while(r && r.nodeName != '#document' && !up) { // find parent context
		if(r.hasAttribute('selectable'))
		    up = r.getAttribute('id');
		r = r.parentNode;
	    }
	    if(!up) { // default parent-context (doc)
		    window.location = window.location.pathname;
	    } else { // parent-context
		window.location.hash = up;
	    };
	} else { // doc-context
	    var up = document.querySelector("head > link[rel='parent']")
	    if(up) {
		document.location = up.getAttribute('href');
	    } else {
		window.history.back();
	    };
	};
    };

    // enter context
    // <enter> 
    if(e.keyCode==13){
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

    // history
    if(e.keyCode==66) // (b)ack
	window.history.back();
    if(e.keyCode==70) // (f)orward
	window.history.forward();

},false);

window.addEventListener("hashchange",function(e){
    var id = window.location.hash.slice(1);
    var resource = document.getElementById(id);
    if(resource) {
	var resTitle = resource.getAttribute('href');
	document.querySelector('title').innerText = resTitle;
	window.scrollTo(resource.offsetLeft + (resource.clientWidth / 2) - (window.width / 2), window.scrollY);
    };
});
