N = NodeList.prototype;
E = Element.prototype;
N.map = function(f,a){for(var i=0,l=this.length;i<l;i++) f.apply(this[i],a);return this};
E.attr = function(a,v){
    if(v){ this.setAttribute(a,String(v))
	   return this
	 } else { return this.getAttribute(a)}};
var prev = null;
var first = null;

// add navigation pointers to elements
document.querySelectorAll('[id]').map(function(e){
    if(!first)
	first = this;
    this.attr('next',first.attr('id'));
    first.attr('prev',this.attr('id'));
    if(prev){
	this.attr('prev',prev.attr('id'));
	prev.attr('next',this.attr('id'));
    };
    prev = this;
});

document.addEventListener("keydown",function(e){
    
    var jumpDoc = function(direction, start) {
	var doc = document.querySelector("head > link[rel='"+direction+"']");
	if(doc)
	    window.location = doc.getAttribute('href') + start;
    };
    // pagination key-control
    var key = e.keyCode;
//    console.log(key);

    if(e.getModifierState("Shift")) {
	if(key==80) // previous page
	    jumpDoc('prev','#last');
	if(key==78) // next page
	    jumpDoc('next','#first');
    };

    if(key==38){ // previous selection
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
    if(key==40){ // next selection
	var loc = window.location.hash;
	var cur = null;
	if(loc)
	    cur = document.querySelector(loc);
	if(!cur) {
	    window.location.hash = first.attr('id');
	} else {
	    if(cur.attr('id')=='next'){
		window.location = cur.attr('href'); // next element is on following page
	    } else {
		window.location.hash = cur.attr('next'); // next element in-page
	    };
	};
    };
    if(key==37) // exit
	window.location = document.referrer;
	//	window.history.back;
    if(key==13||key==39){ // enter
	loc = window.location.hash;
	if(loc){
	    cur = document.querySelector(loc);
	    if(cur){
		href = cur.attr('href');
		if(href)
		    window.location = href;
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
