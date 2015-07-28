
document.addEventListener("keydown",function(e){

    var id = window.location.hash.slice(1);
    var resource = document.getElementById(id);

    var prev = function() {
	if(resource) {
	    var sib = resource.previousSibling;
	    console.log(resource,'res',sib);
	    if(sib) { // previous entry
		var prevId = sib.getAttribute("id");
		if(prevId)
		    window.location.hash = prevId;
	    } else { // wrap
		console.log('wrap',resource);
		var loop = resource.parentNode.querySelector('[selectable]:last-child');
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
		    var loop = resource.parentNode.querySelector('[selectable]');
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

//    console.log(e.keyCode);

    // previous entry
    // <up-arrow>
    if(e.keyCode==38) {
	e.preventDefault();
	if (event.getModifierState("Shift")) {
	    next();
	} else {
	    prev();
	};
    };

    // next entry
    // n <down-arrow> <tab>
    if(e.keyCode==40 || e.keyCode==78 || e.keyCode==9){
	e.preventDefault();
	if (event.getModifierState("Shift")) {
	    prev();
	} else {
	    next();
	};
    };

    // exit context
    // <left-arrow> <esc>

    // enter context
    // <enter> <right-arrow>
    if(e.keyCode == 39|| e.keyCode==13){
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

    // back
    if(e.keyCode==80) // p
	window.history.back();

},false);
