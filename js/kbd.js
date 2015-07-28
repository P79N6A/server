
document.addEventListener("keydown",function(e){

    var id = window.location.hash.slice(1);
    var resource = document.getElementById(id);
//    console.log(e.keyCode);

    // p, <left-arrow> <-
    if(e.keyCode==37 || e.keyCode==80){
	e.preventDefault();	
	window.history.back();
    };

    // n, <right-arrow> ->, <tab>
    if(e.keyCode==39 || e.keyCode==78 || e.keyCode==9){
	e.preventDefault();
	if (event.getModifierState("Shift")) {
	    window.history.back();
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
		    } else { // resource-sequence end
//			window.location = document.referrer;
		    };
		};
	    } else { // no focused-resource bound
		var cur = document.querySelector('[id][selectable]');
		if(cur)
		    window.location.hash = cur.getAttribute('id');
	    };
	};
    };

    // <enter>
    if(e.keyCode==13){
	if(resource) {
	    var href = resource.getAttribute("href");
	    if(href) {
		e.preventDefault();
		document.location = href;
	    };
	};
    };

},false);
