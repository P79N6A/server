document.addEventListener("keydown",function(e){
    
    var jumpDoc = function(direction, start) {
	var doc = document.querySelector("head > link[rel='"+direction+"']");
	if(doc)
	    window.location = doc.getAttribute('href') + start;
    };
    // pagination key-control
    var key = e.keyCode;
    if(e.getModifierState("Shift")) {
	// <shift-p> goto prev-page
	if(key==80)
	    jumpDoc('prev','#last')
	
	// <shift-n> goto next-page
	if(key==78)
	    jumpDoc('next','#first');
    };
},false);

// if JS support exists, switch to JS UI to resource
document.addEventListener("DOMContentLoaded", function(){
    var upgrade = function(){
//	console.log('upgrade UI');
	var id = window.location.hash.slice(1);
	if(id) {
//	    console.log('id',id);
	    var resource = document.getElementById(id);
	    if(resource) {
//		console.log('resource',resource);
		var ui = resource.getAttribute('upgrade');
		if (ui) {
		    console.log('ui',ui);
		};
	    };
	};
    };
    if(window.location.hash)
	upgrade();
    window.addEventListener('hashchange',upgrade);
}, false);
