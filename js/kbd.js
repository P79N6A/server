
document.addEventListener("keydown",function(e){

    var id = window.location.hash.slice(1);
    var resource = document.getElementById(id);

    var prev = function() {
	
    };

    var next = function() {

    };

//    console.log(e.keyCode);

    // previous location
    if(e.keyCode==80) // p
	window.history.back();

    // previous entry
    // <up-arrow>
    if(e.keyCode==38)
	prev();

    // next entry
    // n <down-arrow> <tab>
    if(e.keyCode==40 || e.keyCode==78 || e.keyCode==9){
	e.preventDefault();
	if (event.getModifierState("Shift")) {
	    prev();
	} else {
	    if(resource) {	// current resource
		var explicitNext = resource.getAttribute("next");
		if(explicitNext) { // next by declaration
		    window.location = explicitNext;
		} else {
		    var nextSibling = resource.nextSibling;
		    if(nextSibling) { // next in sequence
			var nextId = nextSibling.getAttribute("id");
			if(nextId) {
			    window.location.hash = nextId;
			};
		    } else { // sequence-end
			var loop = resource.parentNode.querySelector('[selectable]');
			if(loop)
			    window.location.hash = loop.getAttribute("id");
		    };
		};
	    } else { // no focused-resource bound
		var cur = document.querySelector('[id][selectable]');
		if(cur)
		    window.location.hash = cur.getAttribute('id');
	    };
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

},false);
