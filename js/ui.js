N = NodeList.prototype;
E = Element.prototype;
N.map = function(f,a){for(var i=0,l=this.length;i<l;i++) f.apply(this[i],a);return this};
E.attr = function(a,v){
    if(v){ this.setAttribute(a,String(v))
	   return this
	 } else { return this.getAttribute(a)}};
var el = null;
var first = null;
document.querySelectorAll('[id]').map(function(e){
    if(!first)
	first = this;
    this.attr('next',first.attr('id'));
    first.attr('prev',this.attr('id'));
    if(el){
	this.attr('prev',el.attr('id'));
	el.attr('next',this.attr('id'));
    };
    el = this;
});
document.addEventListener("keydown",function(e){
    
    var jumpDoc = function(direction, start) {
	var doc = document.querySelector("head > link[rel='"+direction+"']");
	if(doc)
	    window.location = doc.getAttribute('href') + start;
    };
    // pagination key-control
    var key = e.keyCode;
    document.querySelector('#stderr').innerText = key;
    if(e.getModifierState("Shift")) {
	// <shift-p> goto prev-page
	if(key==80)
	    jumpDoc('prev','#last')
	
	// <shift-n> goto next-page
	if(key==78)
	    jumpDoc('next','#first');
    };
    if(key==37||key==38){
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
    };
    if(key==39||key==40){
	loc = window.location.hash
	if(loc) {
	    cur = document.querySelector(loc);
	    if(!cur)
		cur = first;
	} else {
	    cur = first;
	};
	var p = cur.attr('next');
	window.location.hash = p;
    };
    if(key==13){
	loc = window.location.hash;
	if(loc){
	    cur = document.querySelector(loc);
	    if(cur){
		window.location = cur.attr('href');
	    };
	};
    };
},false);

// if JS support exists, switch to JS UI to resource
document.addEventListener("DOMContentLoaded", function(){
    var upgrade = function(){
	var id = window.location.hash.slice(1);
	if(id) {
	    var resource = document.getElementById(id);
	    if(resource) {
		var ui = resource.getAttribute('upgrade');
		if (ui) {
//		    window.location = ui;
		    console.log('upgrade-UI at ' + ui)
		};
	    };
	};
    };
  // goto UI
    upgrade();
    window.addEventListener('hashchange',upgrade);

}, false);
